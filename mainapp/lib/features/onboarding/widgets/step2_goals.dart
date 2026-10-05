import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';

class Step2Goals extends ConsumerWidget {
  const Step2Goals({super.key});

  static const List<String> availableGoals = [
    'Work or study',
    'Anxious thoughts',
    'Sleep',
    'Burnout',
    'Feeling low or lonely',
    'Physical tension',
    'Panic moments',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What tends to weigh on you?",
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            "Select all that apply.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableGoals.map((goal) {
              final isSelected = state.goals.contains(goal);
              
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(onboardingProvider.notifier).toggleGoal(goal);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
