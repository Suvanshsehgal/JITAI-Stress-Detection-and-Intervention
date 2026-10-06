import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../jitai/models/jitai_user_response.dart';
import '../../jitai/providers/jitai_providers.dart';
import '../../sync/providers/sync_provider.dart';
import '../../toolbox/providers/session_history_provider.dart';
import '../../toolbox/models/intervention_session.dart';
import '../../../shared/widgets/ebb_button.dart';
import '../../../shared/widgets/ebb_card.dart';

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

    // 2. Record response in JITAI repository for sync to backend/Supabase
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

    // 3. Trigger background sync attempt
    ref.read(syncProvider.notifier).syncNow();

    // 4. Return to app
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/toolbox');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moods = [
      {'label': 'Great', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.teal},
      {'label': 'Good', 'icon': Icons.sentiment_satisfied, 'color': Colors.green},
      {'label': 'Okay', 'icon': Icons.sentiment_neutral, 'color': Colors.amber},
      {'label': 'Struggling', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.orange},
      {'label': 'Bad', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.redAccent},
    ];

    final durationSec =
        DateTime.now().difference(widget.startedAt).inSeconds.clamp(1, 7200);
    final durationMinutes = (durationSec / 60).ceil();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer.withAlpha(160),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Great job.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You dedicated ~$durationMinutes min to restore steady-state balance.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How do you feel right now?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: moods.map((item) {
                        final label = item['label'] as String;
                        final icon = item['icon'] as IconData;
                        final color = item['color'] as Color;
                        final isSelected = _selectedMood == label;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedMood = isSelected ? null : label;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : color,
                                      size: 26,
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        label,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
