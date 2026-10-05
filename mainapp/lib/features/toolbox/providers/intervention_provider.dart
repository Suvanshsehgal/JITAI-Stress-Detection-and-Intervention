import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intervention.dart';

final interventionCatalogProvider = Provider<List<Intervention>>((ref) {
  return [
    const Intervention(
      id: 'box-breathing',
      title: 'Box Breathing',
      description: 'A simple technique to maintain your steady state and clear your mind.',
      category: InterventionCategory.calmDown,
      duration: '3 min',
      difficulty: 'Easy',
      icon: 'wind', // Can map to actual icons in UI
      instructions: [
        'Inhale deeply for 4 seconds.',
        'Hold your breath for 4 seconds.',
        'Exhale slowly for 4 seconds.',
        'Hold your breath for 4 seconds.',
      ],
      type: InterventionType.breathing,
      metadata: {
        'cycles': 5,
        'phaseDurationMs': 4000,
      },
    ),
    const Intervention(
      id: '54321-grounding',
      title: '5-4-3-2-1 Grounding',
      description: 'Engage your senses to quickly ground yourself in the present moment.',
      category: InterventionCategory.reset,
      duration: '5 min',
      difficulty: 'Easy',
      icon: 'nature',
      instructions: [
        'Find 5 things you can see around you.',
        'Acknowledge 4 things you can physically feel.',
        'Listen for 3 distinct sounds.',
        'Identify 2 things you can smell.',
        'Focus on 1 thing you can taste.',
      ],
      type: InterventionType.stepGuided,
    ),
    const Intervention(
      id: 'focus-reset',
      title: 'Focus Reset',
      description: 'A quick sequence to sharpen your attention when distracted.',
      category: InterventionCategory.focus,
      duration: '2 min',
      difficulty: 'Medium',
      icon: 'center_focus_strong',
      instructions: [
        'Close your eyes and take one deep breath.',
        'Identify your single most important task right now.',
        'Visualize yourself completing it.',
      ],
      type: InterventionType.timerSequence,
      metadata: {
        'phases': [
          {'title': 'Deep Breath', 'durationMs': 10000},
          {'title': 'Identify One Task', 'durationMs': 20000},
          {'title': 'Visualize Completion', 'durationMs': 15000},
        ]
      },
    ),
    const Intervention(
      id: 'body-release',
      title: 'Body Release',
      description: 'Release physical tension from head to toe.',
      category: InterventionCategory.body,
      duration: '4 min',
      difficulty: 'Easy',
      icon: 'self_improvement',
      instructions: [
        'Tense your shoulders, then release.',
        'Clench your hands, then let go.',
        'Tighten your leg muscles, then relax them.',
      ],
      type: InterventionType.timerSequence,
      metadata: {
        'phases': [
          {'title': 'Shoulders', 'durationMs': 15000},
          {'title': 'Hands', 'durationMs': 15000},
          {'title': 'Legs', 'durationMs': 15000},
        ]
      },
    ),
  ];
});

final recommendationProvider = Provider<Intervention?>((ref) {
  // Deterministic mock recommendation for Phase 4
  final catalog = ref.watch(interventionCatalogProvider);
  return catalog.firstWhere((i) => i.id == 'box-breathing');
});
