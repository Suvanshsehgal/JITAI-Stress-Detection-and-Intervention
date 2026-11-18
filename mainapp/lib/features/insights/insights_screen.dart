import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../shared/widgets/ebb_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final weeklyScores = [
      {'day': 'Mon', 'height': 55.0, 'isHighlight': false},
      {'day': 'Tue', 'height': 75.0, 'isHighlight': false},
      {'day': 'Wed', 'height': 68.0, 'isHighlight': false},
      {'day': 'Thu', 'height': 52.0, 'isHighlight': false},
      {'day': 'Fri', 'height': 48.0, 'isHighlight': true},
      {'day': 'Sat', 'height': 65.0, 'isHighlight': false},
      {'day': 'Sun', 'height': 42.0, 'isHighlight': false},
    ];

    final triggers = [
      {'title': 'Exam weeks', 'points': '+18 points'},
      {'title': 'Late nights', 'points': '+11 points'},
      {'title': 'Crowded places', 'points': '+7 points'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const Text(
              'Last 7 days pattern analysis',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Average stress score
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.lightTextPrimary,
                            ),
                            children: [
                              TextSpan(text: 'Average score: '),
                              TextSpan(
                                text: '41, Moderate',
                                style: TextStyle(
                                  color: AppColors.lightWarm,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightWarmSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '-4 vs last week',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightWarm,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 110,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyScores.map((item) {
                          final day = item['day'] as String;
                          final height = item['height'] as double;
                          final isHighlight = item['isHighlight'] as bool;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: height,
                                decoration: BoxDecoration(
                                  color: isHighlight ? AppColors.lightAccent : const Color(0xFFE4D9CE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isHighlight ? const Color(0xFFD86749) : const Color(0xFFD4C8BC),
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                                  color: isHighlight ? AppColors.lightAccent : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Top triggers
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top triggers',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        const Text(
                          'Stress impact',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...triggers.map((trigger) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.lightPaper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              trigger['title']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.lightAccentSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                trigger['points']!,
                                style: const TextStyle(
                                  color: AppColors.lightAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: Works best for you (Dark Espresso Card)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightBrand,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: const Color(0xFF4A3832), width: 1.2),
                  boxShadow: AppShadows.lightCardShadow,
                ),
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: AppColors.lightAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'WORKS BEST FOR YOU',
                          style: TextStyle(
                            color: AppColors.lightBrandSubtext,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Box breathing lowers your score by 9 points on average',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90), // Nav bar clearance
            ],
          ),
        ),
      ),
    );
  }
}
