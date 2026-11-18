import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../jitai/providers/jitai_providers.dart';
import '../models/intervention.dart';

final interventionCatalogProvider = Provider<List<Intervention>>((ref) {
  return [
    const Intervention(
      id: 'box-breathing',
      title: 'Box breathing',
      description: 'A simple technique to maintain your steady state and clear your mind.',
      category: InterventionCategory.calmDown,
      duration: '2 min',
      difficulty: 'Breathing',
      icon: '0xFFEE7A5C', // Coral dot
      instructions: [
        'Inhale deeply for 4 seconds.',
        'Hold your breath for 4 seconds.',
        'Exhale slowly for 4 seconds.',
        'Hold your breath for 4 seconds.',
      ],
      type: InterventionType.breathing,
      metadata: {
        'cycles': 4,
        'phaseDurationMs': 4000,
      },
    ),
    const Intervention(
      id: '54321-grounding',
      title: '5-4-3-2-1 grounding',
      description: 'Engage your senses to quickly ground yourself in the present moment.',
      category: InterventionCategory.reset,
      duration: '3 min',
      difficulty: 'Grounding',
      icon: '0xFF8DAA59', // Olive green dot
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
      id: 'body-scan',
      title: 'Body scan',
      description: 'Release physical tension from head to toe with mindful scanning.',
      category: InterventionCategory.body,
      duration: '5 min',
      difficulty: 'Reflect',
      icon: '0xFFBA68C8', // Lavender purple dot
      instructions: [
        'Close your eyes and breathe into your shoulders.',
        'Release the grip in your hands and fingers.',
        'Relax the muscles in your lower back and legs.',
      ],
      type: InterventionType.timerSequence,
      metadata: {
        'phases': [
          {'title': 'Shoulders & Neck', 'durationMs': 15000},
          {'title': 'Chest & Core', 'durationMs': 15000},
          {'title': 'Legs & Feet', 'durationMs': 15000},
        ]
      },
    ),
    const Intervention(
      id: 'mindful-walk',
      title: 'Mindful walk',
      description: 'Step away from your desk and connect your movement with your breathing.',
      category: InterventionCategory.focus,
      duration: '5 min',
      difficulty: 'Move',
      icon: '0xFFFFCA28', // Golden yellow dot
      instructions: [
        'Walk at a steady, relaxed pace.',
        'Notice the feeling of each step connecting to the ground.',
        'Sync your breath with your stride.',
      ],
      type: InterventionType.stepGuided,
    ),
    const Intervention(
      id: 'worry-journal',
      title: 'Worry journal',
      description: 'Put your intrusive thoughts on paper to clear cognitive bandwidth.',
      category: InterventionCategory.reflect,
      duration: '4 min',
      difficulty: 'Reflect',
      icon: '0xFFA1887F', // Warm brown dot
      instructions: [
        'Write down the biggest thought weighing on your mind.',
        'Identify what is within your control right now.',
        'Set aside the rest for tomorrow.',
      ],
      type: InterventionType.stepGuided,
    ),
    const Intervention(
      id: 'calm-sounds',
      title: 'Calm sounds',
      description: 'Immerse yourself in gentle binaural and ambient rain soundscapes.',
      category: InterventionCategory.immediateHelp,
      duration: 'Any length',
      difficulty: 'Grounding',
      icon: '0xFFFF9800', // Orange dot
      instructions: [
        'Put on your headphones.',
        'Close your eyes and focus on the gentle ambient rhythm.',
      ],
      type: InterventionType.stepGuided,
    ),
  ];
});

final recommendationProvider = Provider<Intervention?>((ref) {
  final jitaiState = ref.watch(jitaiRecommendationNotifierProvider);
  final catalog = ref.watch(interventionCatalogProvider);
  if (jitaiState.activeRecommendation != null) {
    try {
      return catalog.firstWhere(
        (i) => i.id == jitaiState.activeRecommendation!.interventionId,
      );
    } catch (_) {}
  }
  return catalog.first;
});
