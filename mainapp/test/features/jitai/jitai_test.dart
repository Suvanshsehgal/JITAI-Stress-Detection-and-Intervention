import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/features/health/models/calendar_context.dart';
import 'package:mainapp/features/health/models/context_snapshot.dart';
import 'package:mainapp/features/health/models/data_quality.dart';
import 'package:mainapp/features/jitai/models/jitai_user_response.dart';
import 'package:mainapp/features/jitai/repositories/jitai_response_repository.dart';
import 'package:mainapp/features/jitai/services/local_jitai_decision_engine.dart';
import 'package:mainapp/features/stress_detection/models/inference_status.dart';
import 'package:mainapp/features/stress_detection/models/stress_assessment.dart';
import 'package:mainapp/features/stress_detection/models/stress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalJitaiDecisionEngine', () {
    late LocalJitaiDecisionEngine engine;

    setUp(() {
      engine = LocalJitaiDecisionEngine();
    });

    test('recommends box breathing when stressed and user is free', () async {
      final context = ContextSnapshot(
        timestamp: DateTime.now(),
        calendar: CalendarContext(
          state: CalendarBusyState.free,
          timestamp: DateTime.now(),
        ),
      );

      final assessment = StressAssessment(
        id: 'test-assess-1',
        timestamp: DateTime.now(),
        state: StressState.elevated,
        confidence: 0.85,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'mock-1.0',
      );

      final result = await engine.evaluate(
        context: context,
        stressAssessment: assessment,
      );

      expect(result.isRecommended, isTrue);
      expect(result.recommendation, isNotNull);
      expect(result.recommendation!.interventionId, equals('focus-reset'));
      expect(result.statusReason, equals('recommended'));
    });

    test('suppresses intervention when calendar status is busy', () async {
      final context = ContextSnapshot(
        timestamp: DateTime.now(),
        calendar: CalendarContext(
          state: CalendarBusyState.busy,
          timestamp: DateTime.now(),
        ),
      );

      final assessment = StressAssessment(
        id: 'test-assess-2',
        timestamp: DateTime.now(),
        state: StressState.elevated,
        confidence: 0.85,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'mock-1.0',
      );

      final result = await engine.evaluate(
        context: context,
        stressAssessment: assessment,
      );

      expect(result.isRecommended, isFalse);
      expect(result.recommendation, isNull);
      expect(result.statusReason, equals('calendar_busy'));
    });

    test('enforces 15-minute cooldown between recommendations', () async {
      final context = ContextSnapshot(
        timestamp: DateTime.now(),
        calendar: CalendarContext(
          state: CalendarBusyState.free,
          timestamp: DateTime.now(),
        ),
      );

      final assessment = StressAssessment(
        id: 'test-assess-3',
        timestamp: DateTime.now(),
        state: StressState.elevated,
        confidence: 0.85,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'mock-1.0',
      );

      // First decision
      final first = await engine.evaluate(
        context: context,
        stressAssessment: assessment,
      );
      expect(first.isRecommended, isTrue);

      // Second decision immediately after
      final second = await engine.evaluate(
        context: context,
        stressAssessment: assessment,
      );
      expect(second.isRecommended, isFalse);
      expect(second.statusReason, equals('in_cooldown'));
    });

    test('idempotency: same request returns identical cached result', () async {
      final context = ContextSnapshot(
        timestamp: DateTime.now(),
        calendar: CalendarContext(
          state: CalendarBusyState.free,
          timestamp: DateTime.now(),
        ),
      );

      final assessment = StressAssessment(
        id: 'test-assess-4',
        timestamp: DateTime.now(),
        state: StressState.elevated,
        confidence: 0.85,
        inferenceStatus: InferenceStatus.success,
        dataQuality: DataQualityStatus.available,
        modelVersion: 'mock-1.0',
      );

      final res1 = await engine.evaluate(
        context: context,
        stressAssessment: assessment,
        idempotencyKey: 'request-key-123',
      );

      final res2 = await engine.evaluate(
        context: context,
        stressAssessment: assessment,
        idempotencyKey: 'request-key-123',
      );

      expect(res1.recommendation?.id, equals(res2.recommendation?.id));
      expect(res1.isRecommended, equals(res2.isRecommended));
    });
  });

  group('LocalJitaiResponseRepository', () {
    late LocalJitaiResponseRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = LocalJitaiResponseRepository(prefs);
    });

    test('saves and retrieves responses with pending sync', () async {
      final response = JitaiUserResponse(
        id: 'resp-uuid-1',
        recommendationId: 'rec-1',
        interventionId: 'box-breathing',
        responseType: JitaiResponseType.accepted,
        timestamp: DateTime.now(),
      );

      await repo.recordResponse(response);

      final all = await repo.getAllResponses();
      expect(all.length, 1);
      expect(all.first.recommendationId, 'rec-1');
      expect(all.first.syncStatus, SyncStatus.pending);

      final pending = await repo.getPendingResponses();
      expect(pending.length, 1);

      // Mark as synced
      await repo.markAsSynced(['resp-uuid-1']);
      final remainingPending = await repo.getPendingResponses();
      expect(remainingPending, isEmpty);
    });
  });
}
