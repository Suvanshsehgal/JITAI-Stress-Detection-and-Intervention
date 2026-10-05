import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../toolbox/models/intervention.dart';

class SequenceRunner extends StatefulWidget {
  final Intervention intervention;

  const SequenceRunner({super.key, required this.intervention});

  @override
  State<SequenceRunner> createState() => _SequenceRunnerState();
}

class _SequenceRunnerState extends State<SequenceRunner> with SingleTickerProviderStateMixin {
  late final DateTime _startedAt;
  
  int _currentPhase = 0;
  bool _isPaused = false;
  Timer? _timer;
  
  late AnimationController _animController;
  late List<Map<String, dynamic>> _phases;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _phases = List<Map<String, dynamic>>.from(widget.intervention.metadata['phases'] ?? []);
    
    if (_phases.isNotEmpty) {
      _startPhase();
    }
  }

  void _startPhase() {
    final durationMs = _phases[_currentPhase]['durationMs'] as int;
    
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..forward();

    _timer = Timer(Duration(milliseconds: durationMs), _onPhaseComplete);
  }

  void _onPhaseComplete() {
    if (!mounted) return;

    _animController.dispose();

    if (_currentPhase < _phases.length - 1) {
      setState(() {
        _currentPhase++;
      });
      _startPhase();
    } else {
      _finish();
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
      final remainingMs = (_animController.duration!.inMilliseconds * (1 - _animController.value)).round();
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
      if (!_isPaused && mounted) _pauseOrResume();
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
    if (mounted && _phases.isNotEmpty) {
      try {
        _animController.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phases.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.intervention.title)),
        body: const Center(child: Text('No phases defined.')),
      );
    }

    final theme = Theme.of(context);
    final phase = _phases[_currentPhase];
    final title = phase['title'] as String;

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
                'Phase ${_currentPhase + 1} of ${_phases.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animController.value,
                  );
                },
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
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
