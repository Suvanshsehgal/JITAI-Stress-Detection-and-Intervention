import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../models/calendar_context.dart';
import '../models/context_snapshot.dart';
import '../models/data_quality.dart';
import '../models/health_permission.dart';
import '../models/notification_capability.dart';
import '../providers/health_providers.dart';

class ContextSummaryCard extends ConsumerWidget {
  const ContextSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshotAsync = ref.watch(contextSnapshotProvider);

    return snapshotAsync.when(
      data: (snapshot) => _buildContent(context, theme, snapshot),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => EbbCard(
        child: Text(
          'Unable to load contextual signals.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ThemeData theme, ContextSnapshot snapshot) {
    final calState = snapshot.calendar?.state ?? CalendarBusyState.unknown;
    final notifState = snapshot.notificationCapability?.status ??
        NotificationCapabilityStatus.unknown;

    return Semantics(
      label: 'Context Snapshot Overview. Calendar is ${calState.label}. Notifications are ${notifState.label}.',
      child: EbbCard(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Context Snapshot',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    label: 'Calendar',
                    value: calState.label,
                    icon: Icons.event,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    label: 'Notifications',
                    value: notifState.label,
                    icon: Icons.notifications_active_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    label: 'Heart Rate',
                    value: snapshot.heartRate != null
                        ? '${snapshot.heartRate!.bpm.round()} bpm'
                        : snapshot.getStatusFor(HealthDataType.heartRate).label,
                    icon: Icons.favorite_border,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    label: 'Sleep',
                    value: snapshot.sleep != null
                        ? snapshot.sleep!.formattedDuration
                        : snapshot.getStatusFor(HealthDataType.sleep).label,
                    icon: Icons.bedtime_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.hasAnyHealthData
                  ? 'Real-time readings active.'
                  : 'No wearable connected. Ebb functions normally without physiological data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
