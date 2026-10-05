import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';
import '../../../shared/widgets/ebb_card.dart';

class MoodCheckInWidget extends ConsumerWidget {
  const MoodCheckInWidget({super.key});

  static const List<Map<String, dynamic>> moods = [
    {'emoji': '😢', 'label': 'Low'},
    {'emoji': '😕', 'label': 'Unsettled'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😁', 'label': 'Great'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMood = ref.watch(homeProvider).selectedMood;

    return EbbCard(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.map((mood) {
              final isSelected = selectedMood == mood['label'];
              return GestureDetector(
                onTap: () {
                  ref.read(homeProvider.notifier).setMood(mood['label']);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(mood['emoji'], style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        mood['label'],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
