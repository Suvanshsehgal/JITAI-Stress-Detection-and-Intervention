import 'package:flutter/foundation.dart';

enum SessionStatus {
  inProgress, completed, abandoned
}

@immutable
class InterventionSession {
  final String id;
  final String interventionId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SessionStatus status;
  final String? postMood;

  const InterventionSession({
    required this.id,
    required this.interventionId,
    required this.startedAt,
    this.completedAt,
    this.status = SessionStatus.inProgress,
    this.postMood,
  });

  InterventionSession copyWith({
    String? id,
    String? interventionId,
    DateTime? startedAt,
    DateTime? completedAt,
    SessionStatus? status,
    String? postMood,
  }) {
    return InterventionSession(
      id: id ?? this.id,
      interventionId: interventionId ?? this.interventionId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      postMood: postMood ?? this.postMood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interventionId': interventionId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'postMood': postMood,
    };
  }

  factory InterventionSession.fromJson(Map<String, dynamic> json) {
    return InterventionSession(
      id: json['id'] as String,
      interventionId: json['interventionId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
      postMood: json['postMood'] as String?,
    );
  }
}
