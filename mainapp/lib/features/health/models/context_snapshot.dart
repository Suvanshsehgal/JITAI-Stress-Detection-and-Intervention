import 'package:flutter/foundation.dart';
import 'data_quality.dart';
import 'health_permission.dart';
import 'heart_rate_sample.dart';
import 'hrv_sample.dart';
import 'sleep_session.dart';
import 'calendar_context.dart';
import 'notification_capability.dart';

@immutable
class ContextSnapshot {
  final DateTime timestamp;
  final HeartRateSample? heartRate;
  final HRVSample? hrv;
  final SleepSession? sleep;
  final CalendarContext? calendar;
  final NotificationCapability? notificationCapability;
  final int? recentMood; // 1-5 scale
  final String? recentInterventionId;
  final Map<HealthDataType, DataQualityStatus> sourceStatuses;

  const ContextSnapshot({
    required this.timestamp,
    this.heartRate,
    this.hrv,
    this.sleep,
    this.calendar,
    this.notificationCapability,
    this.recentMood,
    this.recentInterventionId,
    this.sourceStatuses = const {},
  });

  bool get hasHeartRate => heartRate != null;
  bool get hasHRV => hrv != null;
  bool get hasSleep => sleep != null;
  bool get hasCalendar => calendar != null;
  bool get hasAnyHealthData => hasHeartRate || hasHRV || hasSleep;

  DataQualityStatus getStatusFor(HealthDataType type) {
    return sourceStatuses[type] ?? DataQualityStatus.unavailable;
  }

  ContextSnapshot copyWith({
    DateTime? timestamp,
    HeartRateSample? heartRate,
    HRVSample? hrv,
    SleepSession? sleep,
    CalendarContext? calendar,
    NotificationCapability? notificationCapability,
    int? recentMood,
    String? recentInterventionId,
    Map<HealthDataType, DataQualityStatus>? sourceStatuses,
    bool clearHeartRate = false,
    bool clearHrv = false,
    bool clearSleep = false,
    bool clearCalendar = false,
  }) {
    return ContextSnapshot(
      timestamp: timestamp ?? this.timestamp,
      heartRate: clearHeartRate ? null : (heartRate ?? this.heartRate),
      hrv: clearHrv ? null : (hrv ?? this.hrv),
      sleep: clearSleep ? null : (sleep ?? this.sleep),
      calendar: clearCalendar ? null : (calendar ?? this.calendar),
      notificationCapability: notificationCapability ?? this.notificationCapability,
      recentMood: recentMood ?? this.recentMood,
      recentInterventionId: recentInterventionId ?? this.recentInterventionId,
      sourceStatuses: sourceStatuses ?? this.sourceStatuses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate?.toJson(),
      'hrv': hrv?.toJson(),
      'sleep': sleep?.toJson(),
      'calendar': calendar?.toJson(),
      'notificationCapability': notificationCapability?.toJson(),
      'recentMood': recentMood,
      'recentInterventionId': recentInterventionId,
      'sourceStatuses': sourceStatuses.map((k, v) => MapEntry(k.name, v.name)),
    };
  }

  factory ContextSnapshot.fromJson(Map<String, dynamic> json) {
    final statusMap = <HealthDataType, DataQualityStatus>{};
    if (json['sourceStatuses'] is Map) {
      final rawMap = json['sourceStatuses'] as Map<String, dynamic>;
      for (final entry in rawMap.entries) {
        final type = HealthDataType.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => HealthDataType.heartRate,
        );
        final status = DataQualityStatus.values.firstWhere(
          (e) => e.name == entry.value,
          orElse: () => DataQualityStatus.unavailable,
        );
        statusMap[type] = status;
      }
    }

    return ContextSnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRate: json['heartRate'] != null
          ? HeartRateSample.fromJson(json['heartRate'] as Map<String, dynamic>)
          : null,
      hrv: json['hrv'] != null
          ? HRVSample.fromJson(json['hrv'] as Map<String, dynamic>)
          : null,
      sleep: json['sleep'] != null
          ? SleepSession.fromJson(json['sleep'] as Map<String, dynamic>)
          : null,
      calendar: json['calendar'] != null
          ? CalendarContext.fromJson(json['calendar'] as Map<String, dynamic>)
          : null,
      notificationCapability: json['notificationCapability'] != null
          ? NotificationCapability.fromJson(
              json['notificationCapability'] as Map<String, dynamic>)
          : null,
      recentMood: json['recentMood'] as int?,
      recentInterventionId: json['recentInterventionId'] as String?,
      sourceStatuses: statusMap,
    );
  }

  static ContextSnapshot empty({DateTime? timestamp}) {
    return ContextSnapshot(
      timestamp: timestamp ?? DateTime.now(),
      sourceStatuses: const {
        HealthDataType.heartRate: DataQualityStatus.noData,
        HealthDataType.hrv: DataQualityStatus.noData,
        HealthDataType.sleep: DataQualityStatus.noData,
        HealthDataType.calendar: DataQualityStatus.noData,
        HealthDataType.notifications: DataQualityStatus.unavailable,
      },
    );
  }
}
