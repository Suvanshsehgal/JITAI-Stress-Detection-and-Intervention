import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class RecommendationCard extends StatelessWidget {
  /// Score 0–100. Null = no test done yet.
  final int? stressScore;

  /// 0 = not stressed, 1 = stressed. Null if unavailable.
  final int? stressLabel;

  const RecommendationCard({
    super.key,
    this.stressScore,
    this.stressLabel,
  });

  _RecommendationData get _recommendation {
    // No test done yet
    if (stressScore == null) {
      return _RecommendationData(
        headline: 'Take your first stress assessment',
        action: 'Start a test to get personalised tips',
        icon: Icons.psychology_outlined,
        color: AppColors.primary,
      );
    }

    final isStressed = stressLabel == 1;

    // High stress / stressed label
    if (isStressed || stressScore! < 30) {
      return _RecommendationData(
        headline: 'High stress detected — take a moment',
        action: 'Try a 4-7-8 breathing exercise',
        icon: Icons.air,
        color: const Color(0xFFD64933),
        tips: [
          _Tip(Icons.air, 'Breathe in for 4 sec, hold 7, out for 8'),
          _Tip(Icons.self_improvement, 'Try a 5-min body scan meditation'),
          _Tip(Icons.music_note, 'Listen to calming music or nature sounds'),
        ],
      );
    }

    // Moderate stress
    if (stressScore! < 50) {
      return _RecommendationData(
        headline: 'Moderate stress — a short break will help',
        action: 'Step outside for a 10-min walk',
        icon: Icons.directions_walk,
        color: const Color(0xFFEA9B7E),
        tips: [
          _Tip(Icons.directions_walk, 'Take a short walk outside'),
          _Tip(Icons.water_drop, 'Drink a glass of water and stretch'),
          _Tip(Icons.air, 'Try box breathing: 4 sec in, hold, out, hold'),
        ],
      );
    }

    // Fair
    if (stressScore! < 70) {
      return _RecommendationData(
        headline: 'You\'re doing okay — keep the balance',
        action: 'Try a mindfulness check-in',
        icon: Icons.spa_outlined,
        color: const Color(0xFFE8A547),
        tips: [
          _Tip(Icons.spa_outlined, 'Do a 2-min mindfulness check-in'),
          _Tip(Icons.bedtime_outlined, 'Aim for 7–8 hours of sleep tonight'),
          _Tip(Icons.local_cafe, 'Limit caffeine in the afternoon'),
        ],
      );
    }

    // Good
    if (stressScore! < 85) {
      return _RecommendationData(
        headline: 'Good mental state — keep it up!',
        action: 'Maintain your routine',
        icon: Icons.thumb_up_outlined,
        color: const Color(0xFF2E7D5F),
        tips: [
          _Tip(Icons.fitness_center, 'Keep up your physical activity'),
          _Tip(Icons.people_outline, 'Connect with a friend or family member'),
          _Tip(Icons.book_outlined, 'Journal your thoughts for 5 minutes'),
        ],
      );
    }

    // Excellent
    return _RecommendationData(
      headline: 'Excellent — you\'re thriving!',
      action: 'Share your positive energy',
      icon: Icons.star_outline,
      color: const Color(0xFF2E7D5F),
      tips: [
        _Tip(Icons.star_outline, 'You\'re in great shape — celebrate it'),
        _Tip(Icons.people_outline, 'Help someone who might be stressed'),
        _Tip(Icons.fitness_center, 'Try a new physical challenge today'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = _recommendation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rec.color.withValues(alpha: 0.12),
            rec.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rec.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.headline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          rec.action,
                          style: TextStyle(
                            fontSize: 13,
                            color: rec.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 14, color: rec.color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rec.color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(rec.icon, size: 28, color: rec.color),
              ),
            ],
          ),

          // Tips list
          if (rec.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE0D5CF)),
            const SizedBox(height: 14),
            ...rec.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: rec.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tip.icon, size: 16, color: rec.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary.withValues(alpha: 0.75),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Internal data models ─────────────────────────────────────────────────────

class _Tip {
  final IconData icon;
  final String text;
  const _Tip(this.icon, this.text);
}

class _RecommendationData {
  final String headline;
  final String action;
  final IconData icon;
  final Color color;
  final List<_Tip> tips;

  const _RecommendationData({
    required this.headline,
    required this.action,
    required this.icon,
    required this.color,
    this.tips = const [],
  });
}
