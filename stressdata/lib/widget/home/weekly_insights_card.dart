import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class WeeklyInsightsCard extends StatelessWidget {
  const WeeklyInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weekData = [
      {'day': 'Mon', 'value': 0.6},
      {'day': 'Tue', 'value': 0.8},
      {'day': 'Wed', 'value': 0.5},
      {'day': 'Thu', 'value': 0.9},
      {'day': 'Fri', 'value': 0.7},
      {'day': 'Sat', 'value': 0.4},
      {'day': 'Sun', 'value': 0.6},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Weekly Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((data) {
                return _BarItem(
                  day: data['day'] as String,
                  value: data['value'] as double,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String day;
  final double value;

  const _BarItem({
    required this.day,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 100 * value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryLight,
                AppColors.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
