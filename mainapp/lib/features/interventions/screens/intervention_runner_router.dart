import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../toolbox/providers/intervention_provider.dart';
import '../../toolbox/models/intervention.dart';
import '../runners/breathing_runner.dart';
import '../runners/step_runner.dart';
import '../runners/sequence_runner.dart';

class InterventionRunnerRouter extends ConsumerWidget {
  final String interventionId;

  const InterventionRunnerRouter({super.key, required this.interventionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(interventionCatalogProvider);
    final intervention = catalog.cast<dynamic>().firstWhere(
          (i) => i.id == interventionId,
          orElse: () => null,
        );

    if (intervention == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Intervention not found.')),
      );
    }

    switch (intervention.type) {
      case InterventionType.breathing:
        return BreathingRunner(intervention: intervention);
      case InterventionType.stepGuided:
        return StepRunner(intervention: intervention);
      case InterventionType.timerSequence:
        return SequenceRunner(intervention: intervention);
      case InterventionType.reflection:
        // Placeholder for future type
        return StepRunner(intervention: intervention); 
    }
    
    return const Scaffold(body: Center(child: Text('Unsupported type')));
  }
}
