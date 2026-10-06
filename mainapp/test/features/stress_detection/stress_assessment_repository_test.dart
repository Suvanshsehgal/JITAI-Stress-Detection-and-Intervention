import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mainapp/features/health/models/data_quality.dart';
import 'package:mainapp/features/stress_detection/models/inference_status.dart';
import 'package:mainapp/features/stress_detection/models/stress_assessment.dart';
import 'package:mainapp/features/stress_detection/models/stress_state.dart';
import 'package:mainapp/features/stress_detection/repositories/stress_assessment_repository.dart';

void main() {
  group('LocalStressAssessmentRepository', () {
    late SharedPreferences prefs;
    late LocalStressAssessmentRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LocalStressAssessmentRepository(prefs);
    });

    test('Persists and retrieves successful stress assessments', () async {
      final assessment = StressAssessment(
        id: 'valid-01',
        timestamp: DateTime(2026, 10, 6, 10, 0),
        state: StressState.baseline,
        confidence: 0.90,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'v1.0',
      );

      await repository.saveAssessment(assessment);

      final history = await repository.getAssessmentHistory();
      expect(history.length, 1);
      expect(history.first.id, 'valid-01');

      final latest = await repository.getLatestAssessment();
      expect(latest?.id, 'valid-01');
    });

    test('Never persists failed or insufficientData assessments as historical records', () async {
      final insufficient = StressAssessment(
        id: 'insufficient-01',
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.insufficientData,
        dataQuality: DataQualityStatus.noData,
        modelVersion: 'v1.0',
      );

      final errorAssessment = StressAssessment(
        id: 'err-01',
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.error,
        dataQuality: DataQualityStatus.error,
        modelVersion: 'v1.0',
      );

      await repository.saveAssessment(insufficient);
      await repository.saveAssessment(errorAssessment);

      final history = await repository.getAssessmentHistory();
      expect(history.isEmpty, isTrue,
          reason: 'Failed or incomplete assessments must never be saved to history');
    });

    test('clearHistory removes all persisted assessments', () async {
      final assessment = StressAssessment(
        id: 'valid-02',
        timestamp: DateTime.now(),
        state: StressState.elevated,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'v1.0',
      );

      await repository.saveAssessment(assessment);
      expect((await repository.getAssessmentHistory()).length, 1);

      await repository.clearHistory();
      expect((await repository.getAssessmentHistory()).isEmpty, isTrue);
    });
  });
}
