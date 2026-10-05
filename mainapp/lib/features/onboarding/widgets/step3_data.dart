import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../../shared/widgets/ebb_card.dart';

class Step3Data extends ConsumerWidget {
  const Step3Data({super.key});

  static const List<Map<String, String>> dataOptions = [
    {
      'id': 'hr_hrv',
      'title': 'Heart rate and HRV',
      'subtitle': 'To help measure physical stress responses',
    },
    {
      'id': 'sleep',
      'title': 'Sleep',
      'subtitle': 'To understand your recovery',
    },
    {
      'id': 'calendar',
      'title': 'Calendar (busy or free only)',
      'subtitle': 'To avoid interrupting you',
    },
    {
      'id': 'notifications',
      'title': 'Notifications',
      'subtitle': 'To provide timely support',
    },
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
            "What can I look at?",
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            "These preferences will be used later to request device permissions.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          ...dataOptions.map((option) {
            final isSelected = state.dataPrefs.contains(option['id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: EbbCard(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SwitchListTile(
                  title: Text(option['title']!, style: theme.textTheme.titleMedium),
                  subtitle: Text(option['subtitle']!, style: theme.textTheme.bodySmall),
                  value: isSelected,
                  onChanged: (_) {
                    ref.read(onboardingProvider.notifier).toggleDataPref(option['id']!);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withAlpha(76),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Ebb supports everyday wellbeing. It is not a medical device and does not replace a doctor or therapist.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
