import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'hr_parser.dart';

/// Known watch details (from nRF Connect testing).
const String watchPreferredAddress = '23:09:01:30:04:30';
const String watchNameHint = 'fireboltt'; // matched case-insensitively
const String hrServiceUuid = '000001ff-3c17-d293-8e48-14fe2e4da212';
const String hrCharacteristicHint = 'ff03';

const int maxReadings = 50;
const Duration scanDuration = Duration(seconds: 8);
const Duration connectTimeout = Duration(seconds: 15);
const Duration reconnectDelay = Duration(seconds: 3);

/// What the connection is doing right now.
enum WatchStatus {
  disconnected,
  scanning,
  selecting, // several matching watches found, user must pick one
  connecting,
  connected,
  bluetoothOff,
  permissionDenied,
  error,
}

/// One decoded heart-rate reading.
class HeartRateReading {
  const HeartRateReading({
    required this.time,
    required this.bpm,
    required this.rawHex,
  });

  final DateTime time;
  final int bpm;
  final String rawHex;
}

/// All Bluetooth logic lives here. The UI only reads state and calls methods.
class WatchService extends ChangeNotifier {
  WatchStatus status = WatchStatus.disconnected;
  String message = 'Not connected';

  /// Newest first, capped at [maxReadings].
  final List<HeartRateReading> readings = [];

  /// Watches to pick from when more than one match is found.
  List<BluetoothDevice> candidates = [];

  /// True while the user wants to be connected (controls auto-reconnect).
  bool _active = false;
  bool get isActive => _active;

  HeartRateReading? get current => readings.isEmpty ? null : readings.first;

  BluetoothDevice? _device;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _valueSub;
  Timer? _reconnectTimer;

  // ---------------------------------------------------------------- public

  /// Full flow: permissions, Bluetooth check, scan, then connect.
  Future<void> connect() async {
    _active = true;
    _reconnectTimer?.cancel();

    if (!await _ensurePermissions()) return;
    if (!await _ensureBluetoothOn()) return;
    await _scan();
  }

  /// Called when the user picks one watch from the list.
  Future<void> selectDevice(BluetoothDevice device) async {
    candidates = [];
    await _connectTo(device);
  }

  /// User-initiated disconnect. Stops auto-reconnect.
  Future<void> disconnect() async {
    _active = false;
    _reconnectTimer?.cancel();
    candidates = [];

    await _scanSub?.cancel();
    _scanSub = null;
    await _valueSub?.cancel();
    _valueSub = null;
    await _connSub?.cancel();
    _connSub = null;

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    try {
      await _device?.disconnect();
    } catch (_) {}

    _set(WatchStatus.disconnected, 'Disconnected');
  }

  @override
  void dispose() {
    _active = false;
    _reconnectTimer?.cancel();
    _scanSub?.cancel();
    _valueSub?.cancel();
    _connSub?.cancel();
    _device?.disconnect().catchError((_) {});
    super.dispose();
  }

  // ------------------------------------------------------------ permissions

  Future<bool> _ensurePermissions() async {
    _set(WatchStatus.scanning, 'Requesting Bluetooth permissions...');

    // BLUETOOTH_SCAN / BLUETOOTH_CONNECT exist on Android 12+. Location
    // (ACCESS_FINE_LOCATION) is needed for scanning on Android 11 and below,
    // and on Android 12+ too because the manifest does not set neverForLocation.
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final denied = results.values.any((s) => !s.isGranted);
    if (!denied) return true;

    final permanently = results.values.any((s) => s.isPermanentlyDenied);
    _set(
      WatchStatus.permissionDenied,
      permanently
          ? 'Permission denied. Enable Bluetooth and Location for this app in Settings.'
          : 'Bluetooth and Location permissions are required.',
    );
    _active = false;
    if (permanently) {
      await openAppSettings();
    }
    return false;
  }

  // ------------------------------------------------------------- bluetooth

  Future<bool> _ensureBluetoothOn() async {
    if (!await FlutterBluePlus.isSupported) {
      _stopWithError(WatchStatus.error, 'Bluetooth LE is not supported on this device.');
      return false;
    }

    var state = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 3),
      onTimeout: () => FlutterBluePlus.adapterStateNow,
    );

    if (state != BluetoothAdapterState.on &&
        defaultTargetPlatform == TargetPlatform.android) {
      // Android only: asks the user to turn Bluetooth on.
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
      state = FlutterBluePlus.adapterStateNow;
    }

    if (state != BluetoothAdapterState.on) {
      _stopWithError(WatchStatus.bluetoothOff,
          'Bluetooth is off. Turn it on, then press Connect.');
      return false;
    }
    return true;
  }

  // ------------------------------------------------------------------ scan

  bool _isWatch(ScanResult r) {
    final address = r.device.remoteId.str.toUpperCase();
    if (address == watchPreferredAddress.toUpperCase()) return true;

    final name = (r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName)
        .toLowerCase();
    return name.contains(watchNameHint);
  }

  Future<void> _scan() async {
    _set(WatchStatus.scanning, 'Scanning for the watch...');

    final found = <String, BluetoothDevice>{};
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (_isWatch(r)) {
          found[r.device.remoteId.str.toUpperCase()] = r.device;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: true,
      );
      await Future.delayed(scanDuration);
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('FireboltHR scan error: $e');
      _stopWithError(WatchStatus.error, 'Scan failed: $e');
      return;
    } finally {
      await _scanSub?.cancel();
      _scanSub = null;
    }

    if (!_active) return; // user pressed Disconnect during the scan

    if (found.isEmpty) {
      _stopWithError(WatchStatus.disconnected,
          'Watch not found. Make sure it is on, nearby, and not connected to another phone.');
      return;
    }

    final preferred = found[watchPreferredAddress.toUpperCase()];
    if (preferred != null) {
      await _connectTo(preferred);
    } else if (found.length == 1) {
      await _connectTo(found.values.first);
    } else {
      candidates = found.values.toList();
      _set(WatchStatus.selecting, 'Several matching devices found. Pick your watch.');
    }
  }

  // --------------------------------------------------------------- connect

  Future<void> _connectTo(BluetoothDevice device) async {
    _device = device;
    _reconnectTimer?.cancel();
    _set(WatchStatus.connecting, 'Connecting to ${device.remoteId.str}...');

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: connectTimeout,
        autoConnect: false,
      );
    } catch (e) {
      debugPrint('FireboltHR connect error: $e');
      _scheduleReconnect('Could not connect. Retrying...');
      return;
    }

    // Listen for drops only after a successful connect, so the initial
    // "disconnected" value does not trigger a reconnect.
    await _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });

    try {
      final services = await device.discoverServices();
      _logServices(services);

      final characteristic = _findHrCharacteristic(services);
      if (characteristic == null) {
        await _connSub?.cancel();
        _connSub = null;
        _stopWithError(
            WatchStatus.error,
            'Heart-rate characteristic ($hrCharacteristicHint in $hrServiceUuid) not found.');
        await device.disconnect();
        return;
      }

      await _valueSub?.cancel();
      _valueSub = characteristic.onValueReceived.listen(_onPacket);
      await characteristic.setNotifyValue(true);

      _set(WatchStatus.connected, 'Connected. Waiting for heart-rate data...');
    } catch (e) {
      debugPrint('FireboltHR setup error: $e');
      _scheduleReconnect('Setup failed. Retrying...');
    }
  }

  BluetoothCharacteristic? _findHrCharacteristic(List<BluetoothService> services) {
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() != hrServiceUuid) continue;
      for (final c in service.characteristics) {
        if (c.uuid.toString().toLowerCase().contains(hrCharacteristicHint)) {
          return c;
        }
      }
    }
    return null;
  }

  void _logServices(List<BluetoothService> services) {
    debugPrint('FireboltHR discovered ${services.length} service(s)');
    for (final s in services) {
      debugPrint('FireboltHR service ${s.uuid}');
      for (final c in s.characteristics) {
        debugPrint('FireboltHR   characteristic ${c.uuid} notify=${c.properties.notify}');
      }
    }
  }

  // ----------------------------------------------------------- disconnect

  void _onDisconnected() {
    _valueSub?.cancel();
    _valueSub = null;
    _connSub?.cancel();
    _connSub = null;

    if (!_active) {
      _set(WatchStatus.disconnected, 'Disconnected');
      return;
    }
    _scheduleReconnect('Connection lost. Reconnecting...');
  }

  void _scheduleReconnect(String text) {
    _set(WatchStatus.disconnected, text);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      final device = _device;
      if (_active && device != null) {
        _connectTo(device);
      }
    });
  }

  // ------------------------------------------------------------- packets

  void _onPacket(List<int> bytes) {
    final hex = toHex(bytes);
    final bpm = parseHeartRate(bytes);

    debugPrint('FireboltHR raw=$hex bpm=${bpm ?? 'n/a (not HR or invalid)'}');

    if (bpm == null) return; // other packet types are only logged

    readings.insert(
      0,
      HeartRateReading(time: DateTime.now(), bpm: bpm, rawHex: hex),
    );
    if (readings.length > maxReadings) {
      readings.removeRange(maxReadings, readings.length);
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- helpers

  void _set(WatchStatus newStatus, String text) {
    status = newStatus;
    message = text;
    notifyListeners();
  }

  /// Ends the session (no auto-reconnect) and shows the reason, so the
  /// Connect button becomes available again.
  void _stopWithError(WatchStatus newStatus, String text) {
    _active = false;
    _reconnectTimer?.cancel();
    _set(newStatus, text);
  }
}
