import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../shared/widgets/ebb_card.dart';

class GoalsBadgesScreen extends StatelessWidget {
  const GoalsBadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badges = [
      {'title': 'First reset', 'status': 'Earned', 'icon': Icons.favorite_rounded, 'color': AppColors.lightAccent},
      {'title': '7-day streak', 'status': 'Earned', 'icon': Icons.local_fire_department_rounded, 'color': AppColors.lightAccent},
      {'title': 'Calm night', 'status': 'Earned', 'icon': Icons.nightlight_round, 'color': AppColors.lightAccent},
      {'title': 'Mindful walker', 'status': 'Locked', 'icon': Icons.directions_walk_rounded, 'color': AppColors.lightBorder},
      {'title': 'Journaler', 'status': 'Earned', 'icon': Icons.menu_book_rounded, 'color': AppColors.lightAccent},
      {'title': 'Calm week', 'status': 'Locked', 'icon': Icons.emoji_events_rounded, 'color': AppColors.lightBorder},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Goals and badges'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly goal card
              EbbCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 4 / 5,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightAccent),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '4/5',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'resets',
                                style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly goal',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'One more reset to hit your goal.',
                            style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightPaper,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.lightAccent),
                                SizedBox(width: 4),
                                Text(
                                  '9 day streak',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Badges',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),

              // 3x2 Grid of Badges
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final isEarned = badge['status'] == 'Earned';
                  final color = badge['color'] as Color;
                  final icon = badge['icon'] as IconData;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isEarned ? color.withAlpha(40) : AppColors.lightPaper,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: isEarned ? color : AppColors.lightTextSecondary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isEarned ? AppColors.lightTextPrimary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          badge['status'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isEarned ? AppColors.lightAccent : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Philosophy note
              EbbCard(
                color: AppColors.lightPage,
                child: Center(
                  child: Text(
                    'Goals are about building the habit of resetting, not about keeping your score low.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightTextSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
