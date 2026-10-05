import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../toolbox/providers/intervention_provider.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../../../shared/widgets/ebb_button.dart';

class SuggestedActionWidget extends ConsumerWidget {
  const SuggestedActionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final intervention = ref.watch(recommendationProvider);

    if (intervention == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested for right now',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        EbbCard(
          color: theme.colorScheme.secondaryContainer.withAlpha(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      intervention.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      intervention.duration,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                intervention.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: EbbButton(
                  label: 'Start Session',
                  onPressed: () {
                    context.push('/intervention/${intervention.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
