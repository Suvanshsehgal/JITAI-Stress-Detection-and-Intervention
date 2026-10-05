import 'package:flutter/foundation.dart';

enum InterventionCategory {
  calmDown, reset, focus, sleep, body, reflect, immediateHelp
}

enum InterventionType {
  breathing, stepGuided, timerSequence, reflection
}

@immutable
class Intervention {
  final String id;
  final String title;
  final String description;
  final InterventionCategory category;
  final String duration;
  final String difficulty;
  final String icon;
  final List<String> instructions;
  final InterventionType type;
  final Map<String, dynamic> metadata;

  const Intervention({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.icon,
    required this.instructions,
    required this.type,
    this.metadata = const {},
  });
}
