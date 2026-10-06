import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../models/data_quality.dart';
import '../models/health_permission.dart';
import '../providers/health_providers.dart';

class DataSourceStatusCard extends ConsumerWidget {
  final HealthSourceStatus source;
  final VoidCallback? onRequestPermission;

  const DataSourceStatusCard({
    super.key,
    required this.source,
    this.onRequestPermission,
  });

  IconData _iconForType(HealthDataType type) {
    switch (type) {
      case HealthDataType.heartRate:
        return Icons.favorite_border;
      case HealthDataType.hrv:
        return Icons.monitor_heart_outlined;
      case HealthDataType.sleep:
        return Icons.bedtime_outlined;
      case HealthDataType.calendar:
        return Icons.calendar_today_outlined;
      case HealthDataType.notifications:
        return Icons.notifications_none_outlined;
    }
  }

  Color _statusColor(ThemeData theme, DataQualityStatus status) {
    switch (status) {
      case DataQualityStatus.available:
        return theme.colorScheme.primary;
      case DataQualityStatus.noData:
        return theme.colorScheme.tertiary;
      case DataQualityStatus.stale:
        return Colors.orange;
      case DataQualityStatus.permissionRequired:
        return theme.colorScheme.error;
      case DataQualityStatus.disabled:
        return theme.colorScheme.onSurfaceVariant;
      case DataQualityStatus.unavailable:
      case DataQualityStatus.error:
        return theme.colorScheme.error;
    }
  }

  IconData _statusIcon(DataQualityStatus status) {
    switch (status) {
      case DataQualityStatus.available:
        return Icons.check_circle_outline;
      case DataQualityStatus.noData:
        return Icons.hourglass_empty;
      case DataQualityStatus.stale:
        return Icons.schedule;
      case DataQualityStatus.permissionRequired:
        return Icons.lock_outline;
      case DataQualityStatus.disabled:
        return Icons.block;
      case DataQualityStatus.unavailable:
      case DataQualityStatus.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, source.status);
    final statusIcon = _statusIcon(source.status);

    return Semantics(
      label: '${source.type.displayName}, Status: ${source.status.label}, ${source.isEnabled ? "Enabled" : "Disabled"}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: EbbCard(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForType(source.type),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.type.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            source.status.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: source.isEnabled,
                  onChanged: (value) {
                    ref
                        .read(healthPreferencesProvider.notifier)
                        .setPreference(source.type, value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              source.type.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (source.isEnabled &&
                source.status == DataQualityStatus.permissionRequired) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('Grant Permission'),
                  onPressed: onRequestPermission,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
