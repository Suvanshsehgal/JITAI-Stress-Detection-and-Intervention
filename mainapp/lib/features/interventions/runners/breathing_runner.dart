import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../toolbox/models/intervention.dart';

class BreathingRunner extends StatefulWidget {
  final Intervention intervention;

  const BreathingRunner({super.key, required this.intervention});

  @override
  State<BreathingRunner> createState() => _BreathingRunnerState();
}

class _BreathingRunnerState extends State<BreathingRunner> with SingleTickerProviderStateMixin {
  late final DateTime _startedAt;
  
  int _currentCycle = 0;
  int _totalCycles = 5;
  int _phaseIndex = 0;
  int _phaseDurationMs = 4000;
  
  bool _isPaused = false;
  Timer? _timer;
  
  late AnimationController _animController;

  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    
    _totalCycles = widget.intervention.metadata['cycles'] as int? ?? 5;
    _phaseDurationMs = widget.intervention.metadata['phaseDurationMs'] as int? ?? 4000;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _phaseDurationMs),
    );

    _startPhase();
  }

  void _startPhase() {
    _animController.forward(from: 0);
    _timer = Timer(Duration(milliseconds: _phaseDurationMs), _onPhaseComplete);
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

    if (_currentCycle >= _totalCycles) {
      _finish();
    } else {
      _startPhase();
    }
  }

  void _pauseOrResume() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _timer?.cancel();
      _animController.stop();
    } else {
      final remainingMs = _phaseDurationMs - (_animController.value * _phaseDurationMs).round();
      _animController.forward();
      _timer = Timer(Duration(milliseconds: remainingMs), _onPhaseComplete);
    }
  }

  Future<void> _handleExit() async {
    _timer?.cancel();
    _animController.stop();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Are you sure you want to exit? Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) context.pop();
    } else {
      if (!_isPaused && mounted) _pauseOrResume(); // Resume if wasn't deliberately paused
    }
  }

  void _finish() {
    if (mounted) {
      context.replace('/intervention/${widget.intervention.id}/complete', extra: _startedAt);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phaseName = _phases[_phaseIndex];
    final isExpanded = phaseName == 'Inhale';
    final isShrinking = phaseName == 'Exhale';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.intervention.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleExit,
          ),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cycle ${_currentCycle + 1} of $_totalCycles',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (isExpanded) {
                        scale = 1.0 + (_animController.value * 0.5);
                      } else if (isShrinking) {
                        scale = 1.5 - (_animController.value * 0.5);
                      } else {
                        scale = phaseName == 'Hold' && _phaseIndex == 1 ? 1.5 : 1.0;
                      }

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primaryContainer.withAlpha(150),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            phaseName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: IconButton(
                  iconSize: 64,
                  icon: Icon(_isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled),
                  color: theme.colorScheme.primary,
                  onPressed: _pauseOrResume,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
