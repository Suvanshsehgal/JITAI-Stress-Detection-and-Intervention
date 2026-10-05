import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../toolbox/models/intervention.dart';
import '../../../shared/widgets/ebb_button.dart';

class StepRunner extends StatefulWidget {
  final Intervention intervention;

  const StepRunner({super.key, required this.intervention});

  @override
  State<StepRunner> createState() => _StepRunnerState();
}

class _StepRunnerState extends State<StepRunner> {
  late final DateTime _startedAt;
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  Future<void> _handleExit() async {
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

    if (confirm == true && mounted) {
      context.pop();
    }
  }

  void _next() {
    if (_currentStep < widget.intervention.instructions.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      context.replace('/intervention/${widget.intervention.id}/complete', extra: _startedAt);
    }
  }
  
  void _prev() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instruction = widget.intervention.instructions[_currentStep];
    final totalSteps = widget.intervention.instructions.length;
    final progress = (_currentStep + 1) / totalSteps;

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
            children: [
              LinearProgressIndicator(value: progress),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $totalSteps',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        instruction,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prev,
                          child: const Text('Previous'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: EbbButton(
                        label: _currentStep == totalSteps - 1 ? 'Complete' : 'Next',
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
