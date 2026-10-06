import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/baseline_provider.dart';
import '../../../shared/widgets/ebb_card.dart';

class BaselineProgressCard extends ConsumerWidget {
  const BaselineProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseline = ref.watch(baselineProvider);
    
    final isLearning = baseline.progressPercent < 1.0;
    
    return EbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLearning ? Icons.psychology : Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Baseline Learning',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (baseline.observedDays == 0) ...[
            Text(
              'Welcome to Ebb. As you check in and use the toolbox, Ebb will learn your normal patterns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            LinearProgressIndicator(
              value: baseline.progressPercent,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            Text(
              isLearning 
                  ? 'Ebb is learning your usual patterns. Keep checking in daily.'
                  : 'Ebb has established a baseline of your normal patterns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: baseline.observedDays.toString(),
                  label: 'Days Observed',
                ),
                _StatItem(
                  value: baseline.totalCheckIns.toString(),
                  label: 'Check-ins',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
