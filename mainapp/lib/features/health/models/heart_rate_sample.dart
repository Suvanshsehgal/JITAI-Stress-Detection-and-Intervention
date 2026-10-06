import 'package:flutter/foundation.dart';
import 'data_quality.dart';

@immutable
class HeartRateSample {
  final double bpm;
  final DateTime timestamp;
  final DataQualityStatus quality;

  const HeartRateSample({
    required this.bpm,
    required this.timestamp,
    this.quality = DataQualityStatus.available,
  });

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'timestamp': timestamp.toIso8601String(),
      'quality': quality.name,
    };
  }

  factory HeartRateSample.fromJson(Map<String, dynamic> json) {
    return HeartRateSample(
      bpm: (json['bpm'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      quality: DataQualityStatus.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => DataQualityStatus.available,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateSample &&
          runtimeType == other.runtimeType &&
          bpm == other.bpm &&
          timestamp == other.timestamp &&
          quality == other.quality;

  @override
  int get hashCode => bpm.hashCode ^ timestamp.hashCode ^ quality.hashCode;
}
