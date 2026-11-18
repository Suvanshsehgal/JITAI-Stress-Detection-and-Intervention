import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../toolbox/models/intervention.dart';

class BreathingRunner extends StatefulWidget {
  final Intervention intervention;

  const BreathingRunner({super.key, required this.intervention});

  @override
  State<BreathingRunner> createState() => _BreathingRunnerState();
}

class _BreathingRunnerState extends State<BreathingRunner> with SingleTickerProviderStateMixin {
  late final DateTime _startedAt;

  int _currentCycle = 1;
  int _totalCycles = 4;
  int _phaseIndex = 0;
  int _phaseDurationMs = 4000;
  int _secondsLeftInPhase = 4;

  bool _isPaused = false;
  Timer? _countdownTimer;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    _totalCycles = widget.intervention.metadata['cycles'] as int? ?? 4;
    _phaseDurationMs = widget.intervention.metadata['phaseDurationMs'] as int? ?? 4000;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _phaseDurationMs),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startPhase();
  }

  void _startPhase() {
    _secondsLeftInPhase = (_phaseDurationMs / 1000).round();

    if (_phases[_phaseIndex] == 'Inhale') {
      _animController.forward(from: 0);
    } else if (_phases[_phaseIndex] == 'Exhale') {
      _animController.reverse(from: 1);
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_isPaused) {
        setState(() {
          _secondsLeftInPhase--;
        });
        if (_secondsLeftInPhase <= 0) {
          timer.cancel();
          _onPhaseComplete();
        }
      }
    });
  }

  void _onPhaseComplete() {
    if (!mounted) return;

    setState(() {
      _phaseIndex++;
      if (_phaseIndex >= _phases.length) {
        _phaseIndex = 0;
        _currentCycle++;
      }
    });

    if (_currentCycle > _totalCycles) {
      _finish();
    } else {
      _startPhase();
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _animController.stop();
    } else {
      if (_phases[_phaseIndex] == 'Inhale') {
        _animController.forward();
      } else if (_phases[_phaseIndex] == 'Exhale') {
        _animController.reverse();
      }
    }
  }

  void _finish() {
    _countdownTimer?.cancel();
    _animController.dispose();
    context.replace(
      '/intervention/${widget.intervention.id}/complete',
      extra: _startedAt,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPhaseName = _phases[_phaseIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.intervention.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Central Pacing Double Circle
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.lightAccentSoft.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      color: AppColors.lightAccent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentPhaseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_secondsLeftInPhase',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Subtitle indicator
            Text(
              'Cycle $_currentCycle of $_totalCycles · 1:12 left',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(flex: 2),

            // Bottom action buttons (Pause & Finish)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _togglePause,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
                        foregroundColor: AppColors.lightTextPrimary,
                      ),
                      child: Text(
                        _isPaused ? 'Resume' : 'Pause',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightBrand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Finish',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
