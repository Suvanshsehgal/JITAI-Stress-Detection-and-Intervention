import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/models/data_quality.dart';
import '../../health/models/health_permission.dart';
import '../../health/providers/health_providers.dart';
import '../providers/home_provider.dart';
import '../../../shared/widgets/ebb_card.dart';

class HealthSnapshotWidget extends ConsumerWidget {
  const HealthSnapshotWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fallback = ref.watch(homeProvider).healthSnapshot;
    final snapshotAsync = ref.watch(contextSnapshotProvider);

    final hrValue = snapshotAsync.maybeWhen(
      data: (s) {
        if (s.getStatusFor(HealthDataType.heartRate) == DataQualityStatus.disabled) {
          return 'Disabled';
        }
        if (s.heartRate != null) {
          return '${s.heartRate!.bpm.round()} bpm';
        }
        return fallback.heartRate != null ? '${fallback.heartRate} bpm' : '--';
      },
      orElse: () => fallback.heartRate != null ? '${fallback.heartRate} bpm' : '--',
    );

    final hrvValue = snapshotAsync.maybeWhen(
      data: (s) {
        if (s.getStatusFor(HealthDataType.hrv) == DataQualityStatus.disabled) {
          return 'Disabled';
        }
        if (s.hrv != null) {
          return '${s.hrv!.rmssdMs.round()} ms';
        }
        return fallback.hrv != null ? '${fallback.hrv} ms' : '--';
      },
      orElse: () => fallback.hrv != null ? '${fallback.hrv} ms' : '--',
    );

    final sleepValue = snapshotAsync.maybeWhen(
      data: (s) {
        if (s.getStatusFor(HealthDataType.sleep) == DataQualityStatus.disabled) {
          return 'Disabled';
        }
        if (s.sleep != null) {
          return s.sleep!.formattedDuration;
        }
        return fallback.sleep ?? '--';
      },
      orElse: () => fallback.sleep ?? '--',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Snapshot',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context, 
                'HR', 
                hrValue,
                Icons.favorite_border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context, 
                'HRV', 
                hrvValue,
                Icons.monitor_heart_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context, 
                'Sleep', 
                sleepValue,
                Icons.bedtime_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return EbbCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
