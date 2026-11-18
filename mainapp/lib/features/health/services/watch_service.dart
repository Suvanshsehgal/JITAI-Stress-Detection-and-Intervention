import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'hr_parser.dart';

/// Known watch details (Fireboltt 124 / Fireboltt BLE).
const String watchPreferredAddress = '23:09:01:30:04:30';
const String watchNameHint = 'fireboltt'; // matched case-insensitively
const String hrServiceUuid = '000001ff-3c17-d293-8e48-14fe2e4da212';
const String hrCharacteristicHint = 'ff03';

const int maxReadings = 50;
const Duration scanDuration = Duration(seconds: 8);
const Duration connectTimeout = Duration(seconds: 15);
const Duration reconnectDelay = Duration(seconds: 3);

/// Current state of the Bluetooth watch connection.
enum WatchStatus {
  disconnected,
  scanning,
  selecting, // multiple matching watches found
  connecting,
  connected,
  bluetoothOff,
  permissionDenied,
  error,
}

/// One decoded heart-rate reading from Fireboltt.
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

/// Bluetooth service communicating with the Fireboltt smartwatch.
class WatchService extends ChangeNotifier {
  WatchStatus status = WatchStatus.disconnected;
  String message = 'Not connected';

  /// Newest readings first, capped at [maxReadings].
  final List<HeartRateReading> readings = [];

  /// Found devices when multiple matches are discovered.
  List<BluetoothDevice> candidates = [];

  bool _active = false;
  bool get isActive => _active;

  HeartRateReading? get current => readings.isEmpty ? null : readings.first;

  BluetoothDevice? _device;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _valueSub;
  Timer? _reconnectTimer;

  // Callback whenever a new heart rate reading arrives
  void Function(int bpm)? onHeartRateReceived;

  // ---------------------------------------------------------------- public

  /// Full connection flow: request permissions, ensure BLE on, scan, and connect.
  Future<void> connect() async {
    _active = true;
    _reconnectTimer?.cancel();

    if (!await _ensurePermissions()) return;
    if (!await _ensureBluetoothOn()) return;
    await _scan();
  }

  /// Connect to a specific chosen device.
  Future<void> selectDevice(BluetoothDevice device) async {
    candidates = [];
    await _connectTo(device);
  }

  /// Disconnect and stop auto-reconnect.
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
          ? 'Bluetooth permissions denied. Please enable Bluetooth & Location in device settings.'
          : 'Bluetooth and Location permissions are required to scan for your Fireboltt watch.',
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
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
      state = FlutterBluePlus.adapterStateNow;
    }

    if (state != BluetoothAdapterState.on) {
      _stopWithError(
        WatchStatus.bluetoothOff,
        'Bluetooth is off. Turn on Bluetooth, then press Connect.',
      );
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
    _set(WatchStatus.scanning, 'Scanning for Fireboltt watch...');

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
      debugPrint('Fireboltt scan error: $e');
      _stopWithError(WatchStatus.error, 'Scan failed: $e');
      return;
    } finally {
      await _scanSub?.cancel();
      _scanSub = null;
    }

    if (!_active) return;

    if (found.isEmpty) {
      _stopWithError(
        WatchStatus.disconnected,
        'Watch not found. Ensure your Fireboltt watch is nearby, awake, and not paired to another app.',
      );
      return;
    }

    final preferred = found[watchPreferredAddress.toUpperCase()];
    if (preferred != null) {
      await _connectTo(preferred);
    } else if (found.length == 1) {
      await _connectTo(found.values.first);
    } else {
      candidates = found.values.toList();
      _set(WatchStatus.selecting, 'Multiple watches found. Select your device.');
    }
  }

  // --------------------------------------------------------------- connect

  Future<void> _connectTo(BluetoothDevice device) async {
    _device = device;
    _reconnectTimer?.cancel();
    _set(WatchStatus.connecting, 'Connecting to Fireboltt (${device.remoteId.str})...');

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: connectTimeout,
        autoConnect: false,
      );
    } catch (e) {
      debugPrint('Fireboltt connect error: $e');
      _scheduleReconnect('Could not connect. Retrying...');
      return;
    }

    await _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });

    try {
      final services = await device.discoverServices();
      final characteristic = _findHrCharacteristic(services);

      if (characteristic == null) {
        await _connSub?.cancel();
        _connSub = null;
        _stopWithError(
          WatchStatus.error,
          'Heart-rate characteristic not found on this watch.',
        );
        await device.disconnect();
        return;
      }

      await _valueSub?.cancel();
      _valueSub = characteristic.onValueReceived.listen(_onPacket);
      await characteristic.setNotifyValue(true);

      _set(WatchStatus.connected, 'Connected to Fireboltt. Monitoring heart rate...');
    } catch (e) {
      debugPrint('Fireboltt setup error: $e');
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
    _scheduleReconnect('Connection lost. Reconnecting to watch...');
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

    if (bpm == null) return;

    readings.insert(
      0,
      HeartRateReading(time: DateTime.now(), bpm: bpm, rawHex: hex),
    );
    if (readings.length > maxReadings) {
      readings.removeRange(maxReadings, readings.length);
    }

    onHeartRateReceived?.call(bpm);
    notifyListeners();
  }

  // ------------------------------------------------------------- helpers

  void _set(WatchStatus newStatus, String text) {
    status = newStatus;
    message = text;
    notifyListeners();
  }

  void _stopWithError(WatchStatus newStatus, String text) {
    _active = false;
    _reconnectTimer?.cancel();
    _set(newStatus, text);
  }
}
