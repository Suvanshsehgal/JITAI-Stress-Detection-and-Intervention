import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/ebb_card.dart';

class ThisWeekCard extends StatelessWidget {
  const ThisWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = [
      {'day': 'M', 'height': 38.0, 'isToday': false},
      {'day': 'T', 'height': 60.0, 'isToday': false},
      {'day': 'W', 'height': 48.0, 'isToday': false},
      {'day': 'T', 'height': 32.0, 'isToday': false},
      {'day': 'F', 'height': 24.0, 'isToday': false},
      {'day': 'S', 'height': 44.0, 'isToday': false},
      {'day': 'S', 'height': 52.0, 'isToday': true},
    ];

    return EbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This week',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightPaper,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Daily Reset Activity',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((item) {
              final day = item['day'] as String;
              final height = item['height'] as double;
              final isToday = item['isToday'] as bool;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: height,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.lightAccent : const Color(0xFFE4D9CE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday ? const Color(0xFFD86749) : const Color(0xFFD4C8BC),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: isToday ? AppColors.lightAccent : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
