import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/ebb_card.dart';
import '../stress_detection/widgets/stress_assessment_card.dart';
import 'models/health_permission.dart';
import 'providers/health_providers.dart';
import 'widgets/context_summary_card.dart';
import 'widgets/data_source_status_card.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  Future<void> _handlePermissionRequest(
    BuildContext context,
    WidgetRef ref,
    HealthDataType type,
  ) async {
    final service = ref.read(healthPermissionServiceProvider);
    await service.requestPermission(type);
    // Refresh providers
    ref.invalidate(healthOverviewProvider);
    ref.invalidate(contextSnapshotProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission granted for ${type.displayName}.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(healthOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Context Data'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contextual Signals',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ebb uses lightweight context signals to suggest timely interventions. You are always in control of what is shared.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const ContextSummaryCard(),
              const SizedBox(height: 16),
              const StressAssessmentCard(),
              const SizedBox(height: 24),
              Text(
                'Connected Sources',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              overviewAsync.when(
                data: (sources) {
                  return Column(
                    children: HealthDataType.values.map((type) {
                      final status = sources[type];
                      if (status == null) return const SizedBox.shrink();
                      return DataSourceStatusCard(
                        source: status,
                        onRequestPermission: () =>
                            _handlePermissionRequest(context, ref, type),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading sources: $err'),
                ),
              ),
              const SizedBox(height: 24),
              EbbCard(
                color: theme.colorScheme.secondaryContainer.withAlpha(60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy & Transparency',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No medical diagnosis is performed. Physiological values are never sent to external AI models. Calendar events only distinguish busy from free slots, without reading titles, descriptions, or attendees.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
