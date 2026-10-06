import 'package:flutter/foundation.dart';
import 'data_quality.dart';

@immutable
class HRVSample {
  final double rmssdMs;
  final DateTime timestamp;
  final DataQualityStatus quality;

  const HRVSample({
    required this.rmssdMs,
    required this.timestamp,
    this.quality = DataQualityStatus.available,
  });

  Map<String, dynamic> toJson() {
    return {
      'rmssdMs': rmssdMs,
      'timestamp': timestamp.toIso8601String(),
      'quality': quality.name,
    };
  }

  factory HRVSample.fromJson(Map<String, dynamic> json) {
    return HRVSample(
      rmssdMs: (json['rmssdMs'] as num).toDouble(),
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
      other is HRVSample &&
          runtimeType == other.runtimeType &&
          rmssdMs == other.rmssdMs &&
          timestamp == other.timestamp &&
          quality == other.quality;

  @override
  int get hashCode => rmssdMs.hashCode ^ timestamp.hashCode ^ quality.hashCode;
}
