import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../shared/widgets/ebb_button.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../providers/health_providers.dart';
import '../services/watch_service.dart';

class WatchConnectScreen extends ConsumerWidget {
  const WatchConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(watchServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.lightTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Fireboltt Smartwatch',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              _buildStatusCard(context, watch),
              const SizedBox(height: 16),

              // Device candidate selector (when multiple found)
              if (watch.status == WatchStatus.selecting) ...[
                _buildDevicePicker(context, watch),
                const SizedBox(height: 16),
              ],

              // Central Live BPM Display
              _buildLiveBpmCard(context, watch),
              const SizedBox(height: 16),

              // Connect / Disconnect Buttons
              Row(
                children: [
                  Expanded(
                    child: EbbButton(
                      label: watch.status == WatchStatus.scanning
                          ? 'Scanning...'
                          : (watch.status == WatchStatus.connecting ? 'Connecting...' : 'Connect Watch'),
                      isLoading: watch.status == WatchStatus.scanning || watch.status == WatchStatus.connecting,
                      isAccent: !watch.isActive,
                      onPressed: watch.isActive ? null : () => watch.connect(),
                    ),
                  ),
                  if (watch.isActive) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: EbbButton(
                        label: 'Disconnect',
                        isSecondary: true,
                        onPressed: () => watch.disconnect(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Readings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Real-Time Heart Rate Stream',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightPaper,
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: AppColors.lightBorder, width: 1),
                    ),
                    child: Text(
                      '${watch.readings.length} packets',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Readings List
              Expanded(
                child: _buildReadingsList(context, watch),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, WatchService watch) {
    final statusColor = watch.status == WatchStatus.connected
        ? AppColors.lightCalm
        : (watch.status == WatchStatus.error || watch.status == WatchStatus.permissionDenied
            ? AppColors.lightRose
            : AppColors.lightWarm);

    final statusTitle = switch (watch.status) {
      WatchStatus.disconnected => 'Disconnected',
      WatchStatus.scanning => 'Scanning for Fireboltt...',
      WatchStatus.selecting => 'Select Watch',
      WatchStatus.connecting => 'Connecting...',
      WatchStatus.connected => 'Fireboltt Connected',
      WatchStatus.bluetoothOff => 'Bluetooth Disabled',
      WatchStatus.permissionDenied => 'Permission Required',
      WatchStatus.error => 'Connection Error',
    };

    return EbbCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.watch_rounded, color: statusColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  watch.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicePicker(BuildContext context, WatchService watch) {
    return EbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your Fireboltt device:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final device in watch.candidates)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.watch, color: AppColors.lightAccent),
              title: Text(
                device.platformName.isEmpty ? 'Fireboltt Device' : device.platformName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
              ),
              subtitle: Text(
                device.remoteId.str,
                style: const TextStyle(color: AppColors.lightTextSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.lightTextSecondary),
              onTap: () => watch.selectDevice(device),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveBpmCard(BuildContext context, WatchService watch) {
    final current = watch.current;
    final isConnected = watch.status == WatchStatus.connected;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBrand,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF4A3832), width: 1.2),
        boxShadow: AppShadows.lightCardShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: isConnected ? AppColors.lightAccent : Colors.white54,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE HEART RATE',
                style: TextStyle(
                  color: AppColors.lightBrandSubtext,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            current == null ? '--' : '${current.bpm}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'BPM',
            style: TextStyle(
              color: AppColors.lightAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            current == null
                ? (isConnected ? 'Waiting for pulse packet...' : 'Connect watch to start monitoring')
                : 'Last synced: ${_formatTime(current.time)}',
            style: const TextStyle(
              color: AppColors.lightBrandSubtext,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList(BuildContext context, WatchService watch) {
    if (watch.readings.isEmpty) {
      return EbbCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.monitor_heart_outlined, size: 40, color: AppColors.lightTextSecondary),
                SizedBox(height: 12),
                Text(
                  'No heart rate readings yet.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep watch on your wrist and press Connect.',
                  style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: watch.readings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = watch.readings[i];
        return EbbCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.lightAccentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.lightAccent, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.bpm} BPM',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Packet: ${r.rawHex}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _formatTime(r.time),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
