import 'package:flutter/foundation.dart';
import 'data_quality.dart';

@immutable
class SleepSession {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final DataQualityStatus quality;

  SleepSession({
    required this.startTime,
    required this.endTime,
    Duration? duration,
    this.quality = DataQualityStatus.available,
  }) : duration = duration ?? endTime.difference(startTime);

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'quality': quality.name,
    };
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      duration: json['durationMinutes'] != null
          ? Duration(minutes: json['durationMinutes'] as int)
          : null,
      quality: DataQualityStatus.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => DataQualityStatus.available,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSession &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          duration == other.duration &&
          quality == other.quality;

  @override
  int get hashCode =>
      startTime.hashCode ^
      endTime.hashCode ^
      duration.hashCode ^
      quality.hashCode;
}
