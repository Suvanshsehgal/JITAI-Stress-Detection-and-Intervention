import 'package:flutter/foundation.dart';
import 'data_quality.dart';

enum CalendarBusyState {
  busy,
  free,
  unknown,
}

extension CalendarBusyStateExtension on CalendarBusyState {
  String get label {
    switch (this) {
      case CalendarBusyState.busy:
        return 'Busy';
      case CalendarBusyState.free:
        return 'Free';
      case CalendarBusyState.unknown:
        return 'Unknown';
    }
  }
}

@immutable
class CalendarContext {
  final CalendarBusyState state;
  final DateTime timestamp;
  final DateTime? nextEventStart;
  final DataQualityStatus quality;

  const CalendarContext({
    required this.state,
    required this.timestamp,
    this.nextEventStart,
    this.quality = DataQualityStatus.available,
  });

  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'timestamp': timestamp.toIso8601String(),
      'nextEventStart': nextEventStart?.toIso8601String(),
      'quality': quality.name,
    };
  }

  factory CalendarContext.fromJson(Map<String, dynamic> json) {
    return CalendarContext(
      state: CalendarBusyState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => CalendarBusyState.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      nextEventStart: json['nextEventStart'] != null
          ? DateTime.parse(json['nextEventStart'] as String)
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
      other is CalendarContext &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          timestamp == other.timestamp &&
          nextEventStart == other.nextEventStart &&
          quality == other.quality;

  @override
  int get hashCode =>
      state.hashCode ^
      timestamp.hashCode ^
      nextEventStart.hashCode ^
      quality.hashCode;
}
