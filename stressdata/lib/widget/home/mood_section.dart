import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class MoodSection extends StatelessWidget {
  final double sleepHours;
  final double steps;
  final VoidCallback? onSleepTap;

  /// Score 0–100. Null = no test done yet.
  final int? stressScore;

  /// 0 = not stressed, 1 = stressed. Null if unavailable.
  final int? stressLabel;

  const MoodSection({
    super.key,
    required this.sleepHours,
    required this.steps,
    this.onSleepTap,
    this.stressScore,
    this.stressLabel,
  });

  /// Returns emoji + mood label derived from the stress score/label.
  _MoodData get _moodFromScore {
    if (stressScore == null) {
      return _MoodData('😶', 'No Data');
    }
    if (stressLabel == 1 || stressScore! < 30) {
      return _MoodData('😟', 'Stressed');
    }
    if (stressScore! < 50) {
      return _MoodData('😕', 'Uneasy');
    }
    if (stressScore! < 70) {
      return _MoodData('😐', 'Moderate');
    }
    if (stressScore! < 85) {
      return _MoodData('🙂', 'Good');
    }
    return _MoodData('😊', 'Excellent');
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodFromScore;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSleepTap,
            child: _MoodItem(
              icon: Icons.bedtime_outlined,
              value: sleepHours > 0
                  ? '${sleepHours.toStringAsFixed(1)} hrs'
                  : 'Tap to add',
              label: 'SLEEP',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MoodItem(
            emoji: mood.emoji,
            value: mood.label,
            label: 'MOOD',
            isCenter: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MoodItem(
            icon: Icons.directions_walk_outlined,
            value: steps > 0
                ? steps >= 1
                    ? '${steps.toStringAsFixed(1)}k'
                    : '${(steps * 1000).round()}'
                : '0',
            label: 'STEPS',
          ),
        ),
      ],
    );
  }
}

class _MoodData {
  final String emoji;
  final String label;
  const _MoodData(this.emoji, this.label);
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 32))
          else if (icon != null)
            Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 8),
          if (value != null)
            Flexible(
              child: Text(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
