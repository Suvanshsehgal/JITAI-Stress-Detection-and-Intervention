import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mood_provider.dart';
import '../models/mood_entry.dart';
import '../../../shared/widgets/ebb_card.dart';
import 'package:intl/intl.dart';

class MoodChartCard extends ConsumerWidget {
  const MoodChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final moods = ref.watch(moodProvider);

    return EbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (moods.isEmpty)
            Text(
              'Check in on the Home screen to start building your mood history.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            SizedBox(
              height: 150,
              child: _buildChart(context, moods),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<MoodEntry> moods) {
    // Generate last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
    
    // Group moods by date string (yyyy-mm-dd)
    final moodMap = <String, List<int>>{};
    for (var m in moods) {
      final key = DateFormat('yyyy-MM-dd').format(m.timestamp);
      moodMap.putIfAbsent(key, () => []).add(m.moodValue);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dayWidth = constraints.maxWidth / 7;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: last7Days.map((date) {
            final key = DateFormat('yyyy-MM-dd').format(date);
            final dayMoods = moodMap[key];
            
            // Average if multiple, or 0 if none
            double avgMood = 0;
            if (dayMoods != null && dayMoods.isNotEmpty) {
              avgMood = dayMoods.reduce((a, b) => a + b) / dayMoods.length;
            }

            // Normalize (1-5 scale) to (0.2-1.0 height multiplier)
            final heightMultiplier = avgMood > 0 ? (avgMood / 5.0) : 0.05; // 0.05 is minimal height for missing

            return SizedBox(
              width: dayWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 16,
                        height: constraints.maxHeight * 0.7 * heightMultiplier,
                        decoration: BoxDecoration(
                          color: avgMood > 0 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('E').format(date)[0], // e.g. M, T, W
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
