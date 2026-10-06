import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/features/health/models/calendar_context.dart';
import 'package:mainapp/features/health/models/context_snapshot.dart';
import 'package:mainapp/features/health/models/data_quality.dart';
import 'package:mainapp/features/health/models/heart_rate_sample.dart';
import 'package:mainapp/features/health/models/hrv_sample.dart';
import 'package:mainapp/features/health/models/sleep_session.dart';
import 'package:mainapp/features/stress_detection/models/inference_input.dart';
import 'package:mainapp/features/stress_detection/models/inference_status.dart';
import 'package:mainapp/features/stress_detection/models/stress_assessment.dart';
import 'package:mainapp/features/stress_detection/models/stress_state.dart';

void main() {
  group('Stress Detection Domain Models', () {
    test('StressAssessment serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final assessment = StressAssessment(
        id: 'assessment-001',
        timestamp: now,
        state: StressState.baseline,
        confidence: 0.88,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'ebb-test-model-v1',
        metadata: const {'source': 'unit_test'},
        explanation: const {'summary': 'Resting pattern within normal bounds.'},
      );

      final json = assessment.toJson();
      final fromJson = StressAssessment.fromJson(json);

      expect(fromJson.id, 'assessment-001');
      expect(fromJson.timestamp, now);
      expect(fromJson.state, StressState.baseline);
      expect(fromJson.confidence, 0.88);
      expect(fromJson.inferenceStatus, InferenceStatus.success);
      expect(fromJson.isSuccessful, isTrue);
      expect(fromJson.dataQuality, DataQualityStatus.available);
      expect(fromJson.modelVersion, 'ebb-test-model-v1');
      expect(fromJson.metadata['source'], 'unit_test');
      expect(fromJson.explanation?['summary'],
          'Resting pattern within normal bounds.');
    });

    test('StressAssessment.insufficientData generates non-successful model', () {
      final assessment = StressAssessment.insufficientData(id: 'insufficient-01');

      expect(assessment.id, 'insufficient-01');
      expect(assessment.state, StressState.unknown);
      expect(assessment.inferenceStatus, InferenceStatus.insufficientData);
      expect(assessment.isSuccessful, isFalse);
      expect(assessment.dataQuality, DataQualityStatus.noData);
    });

    test('InferenceStatus provides friendly non-alarming labels and messages', () {
      expect(InferenceStatus.insufficientData.label, 'More Information Needed');
      expect(InferenceStatus.insufficientData.userMessage,
          contains('Keep checking in daily'));
      expect(InferenceStatus.permissionDenied.label, 'Permission Required');
      expect(InferenceStatus.unavailable.label, 'Signals Unavailable');
      expect(InferenceStatus.staleData.label, 'Signals Need Refresh');
      expect(InferenceStatus.error.label, 'Unable to Assess');
      expect(InferenceStatus.success.isSuccess, isTrue);
      expect(InferenceStatus.error.isSuccess, isFalse);
    });

    test('StressState displays non-medical descriptions', () {
      expect(StressState.baseline.label, 'Steady');
      expect(StressState.elevated.label, 'Mildly Elevated');
      expect(StressState.high.label, 'High Activation');
      expect(StressState.unknown.label, 'Observing Patterns');

      expect(StressState.baseline.description,
          'Your signals indicate a steady, balanced state.');
    });

    test('InferenceInput converts from ContextSnapshot without inventing features', () {
      final now = DateTime(2026, 10, 6, 15, 0);
      final snapshot = ContextSnapshot(
        timestamp: now,
        heartRate: HeartRateSample(bpm: 72.0, timestamp: now),
        hrv: HRVSample(rmssdMs: 45.0, timestamp: now),
        sleep: SleepSession(
          startTime: now.subtract(const Duration(hours: 8)),
          endTime: now,
        ),
        calendar: CalendarContext(
          state: CalendarBusyState.free,
          timestamp: now,
        ),
        recentMood: 4,
      );

      final input = InferenceInput.fromContextSnapshot(snapshot);

      expect(input.timestamp, now);
      expect(input.heartRateBpm, 72.0);
      expect(input.hrvRmssdMs, 45.0);
      expect(input.sleepDurationMinutes, 480);
      expect(input.calendarState, 'free');
      expect(input.recentMood, 4);
      expect(input.hasSufficientSignals, isTrue);

      final json = input.toJson();
      final fromJson = InferenceInput.fromJson(json);
      expect(fromJson.heartRateBpm, 72.0);
      expect(fromJson.hrvRmssdMs, 45.0);
    });

    test('InferenceInput detects empty or insufficient signals safely', () {
      final emptySnapshot = ContextSnapshot.empty();
      final input = InferenceInput.fromContextSnapshot(emptySnapshot);

      expect(input.hasHeartRate, isFalse);
      expect(input.hasHrv, isFalse);
      expect(input.hasSufficientSignals, isFalse);
    });
  });
}
