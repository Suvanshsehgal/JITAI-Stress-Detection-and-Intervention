import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/ebb_button.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../../jitai/models/jitai_user_response.dart';
import '../../jitai/providers/jitai_providers.dart';
import '../../sync/providers/sync_provider.dart';
import '../../toolbox/providers/session_history_provider.dart';
import '../../toolbox/models/intervention_session.dart';

class InterventionCompletionScreen extends ConsumerStatefulWidget {
  final String interventionId;
  final DateTime startedAt;

  const InterventionCompletionScreen({
    super.key,
    required this.interventionId,
    required this.startedAt,
  });

  @override
  ConsumerState<InterventionCompletionScreen> createState() =>
      _InterventionCompletionScreenState();
}

class _InterventionCompletionScreenState
    extends ConsumerState<InterventionCompletionScreen> {
  String? _selectedMood;
  final _uuid = const Uuid();

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Great', 'color': Color(0xFF81C784), 'icon': Icons.sentiment_very_satisfied_rounded},
    {'label': 'Good', 'color': Color(0xFFFFD54F), 'icon': Icons.sentiment_satisfied_rounded},
    {'label': 'Okay', 'color': Color(0xFFD7CCC8), 'icon': Icons.sentiment_neutral_rounded},
    {'label': 'Low', 'color': Color(0xFFFFB74D), 'icon': Icons.sentiment_dissatisfied_rounded},
    {'label': 'Stressed', 'color': Color(0xFFBA68C8), 'icon': Icons.sentiment_very_dissatisfied_rounded},
  ];

  void _finish() {
    final now = DateTime.now();

    // 1. Record session in toolbox history
    final session = InterventionSession(
      id: _uuid.v4(),
      interventionId: widget.interventionId,
      startedAt: widget.startedAt,
      completedAt: now,
      status: SessionStatus.completed,
      postMood: _selectedMood,
    );
    ref.read(sessionHistoryProvider.notifier).saveSession(session);

    // 2. Record response in JITAI repository
    final activeRec =
        ref.read(jitaiRecommendationNotifierProvider).activeRecommendation;
    final jitaiResponse = JitaiUserResponse(
      id: _uuid.v4(),
      recommendationId:
          activeRec?.interventionId == widget.interventionId ? activeRec?.id : null,
      interventionId: widget.interventionId,
      responseType: JitaiResponseType.completed,
      postMood: _selectedMood,
      timestamp: now,
    );
    ref.read(jitaiResponseRepositoryProvider).recordResponse(jitaiResponse);

    // 3. Trigger cloud sync if online
    ref.read(syncProvider.notifier).syncNow();

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Celebration badge
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.lightCalmSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.lightCalm,
                  size: 54,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Reset Complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Taking even two minutes makes a difference for your nervous system.',
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Post-mood prompt
              EbbCard(
                child: Column(
                  children: [
                    Text(
                      'How do you feel right now?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _moods.map((item) {
                        final label = item['label'] as String;
                        final color = item['color'] as Color;
                        final icon = item['icon'] as IconData;
                        final isSelected = _selectedMood == label;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = label),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(isSelected ? 255 : 80),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.lightBrand : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: Icon(icon, color: isSelected ? Colors.white : AppColors.lightTextPrimary, size: 24),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? AppColors.lightTextPrimary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: EbbButton(
                  label: 'Done',
                  onPressed: _finish,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
