import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/watch_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WatchService _watch = WatchService();

  @override
  void dispose() {
    _watch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fireboltt 124 Heart Rate')),
      body: ListenableBuilder(
        listenable: _watch,
        builder: (context, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusCard(
                    status: _watch.status,
                    message: _watch.message,
                  ),
                  const SizedBox(height: 12),
                  if (_watch.status == WatchStatus.selecting)
                    _DevicePicker(
                      devices: _watch.candidates,
                      onPick: _watch.selectDevice,
                    ),
                  _BpmDisplay(reading: _watch.current),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _watch.isActive ? null : _watch.connect,
                          child: const Text('Connect'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _watch.isActive ? _watch.disconnect : null,
                          child: const Text('Disconnect'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last ${_watch.readings.length} readings',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _ReadingsList(readings: _watch.readings),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.message});

  final WatchStatus status;
  final String message;

  String get _label => switch (status) {
        WatchStatus.disconnected => 'Disconnected',
        WatchStatus.scanning => 'Scanning',
        WatchStatus.selecting => 'Scanning',
        WatchStatus.connecting => 'Connecting',
        WatchStatus.connected => 'Connected',
        WatchStatus.bluetoothOff => 'Bluetooth off',
        WatchStatus.permissionDenied => 'Permission denied',
        WatchStatus.error => 'Error',
      };

  @override
  Widget build(BuildContext context) {
    final color = status == WatchStatus.connected
        ? Colors.green
        : (status == WatchStatus.error || status == WatchStatus.permissionDenied)
            ? Colors.red
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.circle, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicePicker extends StatelessWidget {
  const _DevicePicker({required this.devices, required this.onPick});

  final List<BluetoothDevice> devices;
  final void Function(BluetoothDevice) onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final d in devices)
            ListTile(
              leading: const Icon(Icons.watch),
              title: Text(d.platformName.isEmpty ? 'Unnamed device' : d.platformName),
              subtitle: Text(d.remoteId.str),
              onTap: () => onPick(d),
            ),
        ],
      ),
    );
  }
}

class _BpmDisplay extends StatelessWidget {
  const _BpmDisplay({required this.reading});

  final HeartRateReading? reading;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    return Column(
      children: [
        Text(
          r == null ? '-- BPM' : '${r.bpm} BPM',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          r == null ? 'No reading yet' : 'Updated ${formatTime(r.time)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ReadingsList extends StatelessWidget {
  const _ReadingsList({required this.readings});

  final List<HeartRateReading> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('Readings will appear here.'));
    }
    return ListView.separated(
      itemCount: readings.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = readings[i];
        return ListTile(
          dense: true,
          leading: Text(formatTime(r.time)),
          title: Text('${r.bpm} BPM'),
          subtitle: Text(
            r.rawHex,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        );
      },
    );
  }
}

String formatTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
