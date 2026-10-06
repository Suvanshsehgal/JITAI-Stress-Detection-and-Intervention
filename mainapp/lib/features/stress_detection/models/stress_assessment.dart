import 'package:flutter/foundation.dart';
import '../../health/models/data_quality.dart';
import 'inference_status.dart';
import 'stress_state.dart';

@immutable
class StressAssessment {
  final String id;
  final DateTime timestamp;
  final StressState state;
  final double? confidence; // 0.0 to 1.0
  final InferenceStatus inferenceStatus;
  final DataQualityStatus dataQuality;
  final String modelVersion;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic>? explanation;

  const StressAssessment({
    required this.id,
    required this.timestamp,
    required this.state,
    this.confidence,
    required this.inferenceStatus,
    required this.dataQuality,
    required this.modelVersion,
    this.metadata = const {},
    this.explanation,
  });

  bool get isSuccessful => inferenceStatus == InferenceStatus.success;

  StressAssessment copyWith({
    String? id,
    DateTime? timestamp,
    StressState? state,
    double? confidence,
    InferenceStatus? inferenceStatus,
    DataQualityStatus? dataQuality,
    String? modelVersion,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? explanation,
  }) {
    return StressAssessment(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      confidence: confidence ?? this.confidence,
      inferenceStatus: inferenceStatus ?? this.inferenceStatus,
      dataQuality: dataQuality ?? this.dataQuality,
      modelVersion: modelVersion ?? this.modelVersion,
      metadata: metadata ?? this.metadata,
      explanation: explanation ?? this.explanation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'state': state.name,
      'confidence': confidence,
      'inferenceStatus': inferenceStatus.name,
      'dataQuality': dataQuality.name,
      'modelVersion': modelVersion,
      'metadata': metadata,
      'explanation': explanation,
    };
  }

  factory StressAssessment.fromJson(Map<String, dynamic> json) {
    return StressAssessment(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      state: StressState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => StressState.unknown,
      ),
      confidence: (json['confidence'] as num?)?.toDouble(),
      inferenceStatus: InferenceStatus.values.firstWhere(
        (e) => e.name == json['inferenceStatus'],
        orElse: () => InferenceStatus.error,
      ),
      dataQuality: DataQualityStatus.values.firstWhere(
        (e) => e.name == json['dataQuality'],
        orElse: () => DataQualityStatus.unavailable,
      ),
      modelVersion: json['modelVersion'] as String? ?? 'unknown',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      explanation: json['explanation'] != null
          ? Map<String, dynamic>.from(json['explanation'] as Map)
          : null,
    );
  }

  static StressAssessment insufficientData({
    required String id,
    DateTime? timestamp,
    String modelVersion = 'ebb-ml-boundary-v1',
  }) {
    return StressAssessment(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      state: StressState.unknown,
      inferenceStatus: InferenceStatus.insufficientData,
      dataQuality: DataQualityStatus.noData,
      modelVersion: modelVersion,
    );
  }
}
