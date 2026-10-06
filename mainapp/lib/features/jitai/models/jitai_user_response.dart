import 'package:flutter/foundation.dart';

enum JitaiResponseType {
  accepted,
  declined,
  dismissed,
  completed,
  abandoned,
}

enum SyncStatus {
  pending,
  synced,
  failed,
}

@immutable
class JitaiUserResponse {
  final String id;
  final String? recommendationId;
  final String interventionId;
  final JitaiResponseType responseType;
  final DateTime timestamp;
  final String? postMood;
  final SyncStatus syncStatus;

  const JitaiUserResponse({
    required this.id,
    this.recommendationId,
    required this.interventionId,
    required this.responseType,
    required this.timestamp,
    this.postMood,
    this.syncStatus = SyncStatus.pending,
  });

  JitaiUserResponse copyWith({
    String? id,
    String? recommendationId,
    String? interventionId,
    JitaiResponseType? responseType,
    DateTime? timestamp,
    String? postMood,
    SyncStatus? syncStatus,
  }) {
    return JitaiUserResponse(
      id: id ?? this.id,
      recommendationId: recommendationId ?? this.recommendationId,
      interventionId: interventionId ?? this.interventionId,
      responseType: responseType ?? this.responseType,
      timestamp: timestamp ?? this.timestamp,
      postMood: postMood ?? this.postMood,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recommendationId': recommendationId,
      'interventionId': interventionId,
      'responseType': responseType.name,
      'timestamp': timestamp.toIso8601String(),
      'postMood': postMood,
      'syncStatus': syncStatus.name,
    };
  }

  factory JitaiUserResponse.fromJson(Map<String, dynamic> json) {
    return JitaiUserResponse(
      id: json['id'] as String,
      recommendationId: json['recommendationId'] as String?,
      interventionId: json['interventionId'] as String,
      responseType: JitaiResponseType.values.firstWhere(
        (e) => e.name == json['responseType'],
        orElse: () => JitaiResponseType.dismissed,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      postMood: json['postMood'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
    );
  }
}
