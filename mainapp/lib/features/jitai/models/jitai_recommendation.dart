import 'package:flutter/foundation.dart';

@immutable
class JitaiRecommendation {
  final String id;
  final String interventionId;
  final String title;
  final String description;
  final String duration;
  final String reason;
  final String triggerState;
  final DateTime? cooldownUntil;
  final DateTime timestamp;

  const JitaiRecommendation({
    required this.id,
    required this.interventionId,
    required this.title,
    required this.description,
    required this.duration,
    required this.reason,
    required this.triggerState,
    this.cooldownUntil,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interventionId': interventionId,
      'title': title,
      'description': description,
      'duration': duration,
      'reason': reason,
      'triggerState': triggerState,
      'cooldownUntil': cooldownUntil?.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory JitaiRecommendation.fromJson(Map<String, dynamic> json) {
    return JitaiRecommendation(
      id: json['id'] as String,
      interventionId: json['interventionId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      reason: json['reason'] as String,
      triggerState: json['triggerState'] as String,
      cooldownUntil: json['cooldownUntil'] != null
          ? DateTime.parse(json['cooldownUntil'] as String)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
