import 'package:flutter/foundation.dart';
import '../../health/models/context_snapshot.dart';
import '../../health/models/data_quality.dart';
import '../../health/models/health_permission.dart';

@immutable
class InferenceInput {
  final DateTime timestamp;
  final double? heartRateBpm;
  final double? hrvRmssdMs;
  final int? sleepDurationMinutes;
  final String? calendarState;
  final int? recentMood;
  final Map<String, String> dataQualityMap;

  const InferenceInput({
    required this.timestamp,
    this.heartRateBpm,
    this.hrvRmssdMs,
    this.sleepDurationMinutes,
    this.calendarState,
    this.recentMood,
    this.dataQualityMap = const {},
  });

  factory InferenceInput.fromContextSnapshot(ContextSnapshot snapshot) {
    final qualityMap = <String, String>{};
    for (final entry in snapshot.sourceStatuses.entries) {
      qualityMap[entry.key.name] = entry.value.name;
    }

    return InferenceInput(
      timestamp: snapshot.timestamp,
      heartRateBpm: snapshot.heartRate?.bpm,
      hrvRmssdMs: snapshot.hrv?.rmssdMs,
      sleepDurationMinutes: snapshot.sleep?.duration.inMinutes,
      calendarState: snapshot.calendar?.state.name,
      recentMood: snapshot.recentMood,
      dataQualityMap: qualityMap,
    );
  }

  bool get hasHeartRate => heartRateBpm != null;
  bool get hasHrv => hrvRmssdMs != null;
  bool get hasSleep => sleepDurationMinutes != null;

  /// Whether sufficient signals exist to attempt inference.
  bool get hasSufficientSignals => hasHeartRate || hasHrv;

  bool isSourceDisabled(HealthDataType type) {
    return dataQualityMap[type.name] == DataQualityStatus.disabled.name;
  }

  bool isPermissionRequired(HealthDataType type) {
    return dataQualityMap[type.name] ==
        DataQualityStatus.permissionRequired.name;
  }

  bool isStale(HealthDataType type) {
    return dataQualityMap[type.name] == DataQualityStatus.stale.name;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heartRateBpm': heartRateBpm,
      'hrvRmssdMs': hrvRmssdMs,
      'sleepDurationMinutes': sleepDurationMinutes,
      'calendarState': calendarState,
      'recentMood': recentMood,
      'dataQualityMap': dataQualityMap,
    };
  }

  factory InferenceInput.fromJson(Map<String, dynamic> json) {
    return InferenceInput(
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRateBpm: (json['heartRateBpm'] as num?)?.toDouble(),
      hrvRmssdMs: (json['hrvRmssdMs'] as num?)?.toDouble(),
      sleepDurationMinutes: json['sleepDurationMinutes'] as int?,
      calendarState: json['calendarState'] as String?,
      recentMood: json['recentMood'] as int?,
      dataQualityMap: Map<String, String>.from(json['dataQualityMap'] ?? {}),
    );
  }
}
