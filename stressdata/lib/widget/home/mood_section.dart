import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class MoodSection extends StatelessWidget {
  final double sleepHours;
  final double steps;

  const MoodSection({
    super.key,
    required this.sleepHours,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MoodItem(
            icon: Icons.bedtime_outlined,
            value: sleepHours > 0 ? '${sleepHours.toStringAsFixed(1)} hrs' : '0 hrs',
            label: 'SLEEP',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MoodItem(
            emoji: '😊',
            label: 'Current Mood',
            isCenter: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MoodItem(
            icon: Icons.directions_walk_outlined,
            value: steps > 0 ? '${steps.toStringAsFixed(1)}k' : '0k',
            label: 'STEPS',
          ),
        ),
      ],
    );
  }
}

class _MoodItem extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String? value;
  final String label;
  final bool isCenter;

  const _MoodItem({
    this.icon,
    this.emoji,
    this.value,
    required this.label,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (emoji != null)
            const Text(
              '😊',
              style: TextStyle(fontSize: 32),
            )
          else if (icon != null)
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
          const SizedBox(height: 8),
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
