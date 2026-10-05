import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../toolbox/providers/session_history_provider.dart';
import '../../toolbox/models/intervention_session.dart';
import '../../../shared/widgets/ebb_button.dart';

class InterventionCompletionScreen extends ConsumerStatefulWidget {
  final String interventionId;
  final DateTime startedAt;

  const InterventionCompletionScreen({
    super.key, 
    required this.interventionId,
    required this.startedAt,
  });

  @override
  ConsumerState<InterventionCompletionScreen> createState() => _InterventionCompletionScreenState();
}

class _InterventionCompletionScreenState extends ConsumerState<InterventionCompletionScreen> {
  String? _selectedMood;
  final _uuid = const Uuid();

  void _finish() {
    final session = InterventionSession(
      id: _uuid.v4(),
      interventionId: widget.interventionId,
      startedAt: widget.startedAt,
      completedAt: DateTime.now(),
      status: SessionStatus.completed,
      postMood: _selectedMood,
    );
    
    ref.read(sessionHistoryProvider.notifier).saveSession(session);
    
    // Pop back to toolbox or home
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/toolbox');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moods = ['Great', 'Good', 'Okay', 'Struggling', 'Bad'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Great job.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You took a moment for yourself. How are you feeling now?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: moods.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return ChoiceChip(
                    label: Text(mood),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMood = selected ? mood : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: EbbButton(
                  label: 'Done',
                  onPressed: _finish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
