import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/features/health/models/context_snapshot.dart';
import 'package:mainapp/features/health/models/data_quality.dart';
import 'package:mainapp/features/health/models/health_permission.dart';
import 'package:mainapp/features/health/models/heart_rate_sample.dart';
import 'package:mainapp/features/health/models/hrv_sample.dart';
import 'package:mainapp/features/stress_detection/models/inference_input.dart';
import 'package:mainapp/features/stress_detection/models/inference_status.dart';
import 'package:mainapp/features/stress_detection/models/stress_state.dart';
import 'package:mainapp/features/stress_detection/services/mock_stress_detection_service.dart';

void main() {
  group('MockStressDetectionService', () {
    late MockStressDetectionService service;

    setUp(() {
      service = MockStressDetectionService();
    });

    test('Returns permissionDenied when health signals lack permissions', () async {
      final input = InferenceInput(
        timestamp: DateTime.now(),
        dataQualityMap: {
          HealthDataType.heartRate.name: DataQualityStatus.permissionRequired.name,
          HealthDataType.hrv.name: DataQualityStatus.permissionRequired.name,
        },
      );

      final assessment = await service.assess(input);

      expect(assessment.inferenceStatus, InferenceStatus.permissionDenied);
      expect(assessment.isSuccessful, isFalse);
      expect(assessment.state, StressState.unknown);
    });

    test('Returns unavailable when health sources are disabled in preferences', () async {
      final input = InferenceInput(
        timestamp: DateTime.now(),
        dataQualityMap: {
          HealthDataType.heartRate.name: DataQualityStatus.disabled.name,
          HealthDataType.hrv.name: DataQualityStatus.disabled.name,
        },
      );

      final assessment = await service.assess(input);

      expect(assessment.inferenceStatus, InferenceStatus.unavailable);
      expect(assessment.isSuccessful, isFalse);
      expect(assessment.state, StressState.unknown);
    });

    test('Returns staleData when signals need refresh', () async {
      final input = InferenceInput(
        timestamp: DateTime.now(),
        dataQualityMap: {
          HealthDataType.heartRate.name: DataQualityStatus.stale.name,
        },
      );

      final assessment = await service.assess(input);

      expect(assessment.inferenceStatus, InferenceStatus.staleData);
      expect(assessment.isSuccessful, isFalse);
    });

    test('Returns insufficientData when signals are absent without crashing', () async {
      final emptySnapshot = ContextSnapshot.empty();
      final assessment = await service.assessCurrentState(emptySnapshot);

      expect(assessment.inferenceStatus, InferenceStatus.insufficientData);
      expect(assessment.isSuccessful, isFalse);
      expect(assessment.state, StressState.unknown);
    });

    test('Returns success with deterministic assessment when signals are present', () async {
      final now = DateTime.now();
      final snapshot = ContextSnapshot(
        timestamp: now,
        heartRate: HeartRateSample(bpm: 72.0, timestamp: now),
        hrv: HRVSample(rmssdMs: 46.0, timestamp: now),
      );

      final assessment = await service.assessCurrentState(snapshot);

      expect(assessment.inferenceStatus, InferenceStatus.success);
      expect(assessment.isSuccessful, isTrue);
      expect(assessment.state, StressState.baseline);
      expect(assessment.confidence, isNotNull);
      expect(assessment.modelVersion, contains('mock'));
    });

    test('Returns error when error flag is simulated', () async {
      service.shouldThrowError = true;
      final input = InferenceInput(timestamp: DateTime.now());

      final assessment = await service.assess(input);

      expect(assessment.inferenceStatus, InferenceStatus.error);
      expect(assessment.isSuccessful, isFalse);
    });

    test('Explicit verification: no successful assessment is produced on non-success states', () async {
      final nonSuccessStatuses = [
        InferenceStatus.insufficientData,
        InferenceStatus.unavailable,
        InferenceStatus.staleData,
        InferenceStatus.permissionDenied,
        InferenceStatus.error,
      ];

      for (final status in nonSuccessStatuses) {
        service.forcedStatus = status;
        final assessment = await service.assess(InferenceInput(timestamp: DateTime.now()));
        expect(assessment.isSuccessful, isFalse,
            reason: 'Assessment for $status must not be successful');
      }
    });
  });
}
