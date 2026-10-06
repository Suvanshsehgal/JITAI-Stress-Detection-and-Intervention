import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../health/models/context_snapshot.dart';
import '../../stress_detection/models/inference_input.dart';
import '../../stress_detection/models/stress_assessment.dart';
import '../models/jitai_decision_result.dart';
import '../models/jitai_recommendation.dart';
import 'jitai_decision_engine.dart';
import 'local_jitai_decision_engine.dart';

class RemoteJitaiDecisionEngine implements JitaiDecisionEngine {
  final ApiClient _apiClient;
  final LocalJitaiDecisionEngine _localFallback;
  final Uuid _uuid;

  RemoteJitaiDecisionEngine({
    required ApiClient apiClient,
    LocalJitaiDecisionEngine? localFallback,
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _localFallback = localFallback ?? LocalJitaiDecisionEngine(),
        _uuid = uuid ?? const Uuid();

  @override
  Future<JitaiDecisionResult> evaluate({
    required StressAssessment stressAssessment,
    required ContextSnapshot context,
    String idempotencyKey = '',
    List<String> recentInterventions = const [],
  }) async {
    final key = idempotencyKey.isNotEmpty ? idempotencyKey : _uuid.v4();

    try {
      final input = InferenceInput.fromContextSnapshot(context);
      final payload = {
        'idempotencyKey': key,
        'context': input.toJson(),
        'stressAssessment': stressAssessment.toJson(),
        'userTone': 'gentle',
        'recentInterventions': recentInterventions,
      };

      final response = await _apiClient.post('/api/v1/jitai/evaluate', payload);

      if (response != null && response is Map<String, dynamic>) {
        final isRec = response['isRecommended'] as bool? ?? false;
        final statusReason = response['statusReason'] as String? ?? 'unknown';

        if (!isRec) {
          return JitaiDecisionResult(
            isRecommended: false,
            statusReason: statusReason,
          );
        }

        final rec = JitaiRecommendation(
          id: response['recommendationId'] as String? ?? _uuid.v4(),
          interventionId: response['interventionId'] as String? ?? 'box-breathing',
          title: response['title'] as String? ?? 'Box Breathing',
          description: response['description'] as String? ?? 'Regulate activation.',
          duration: response['duration'] as String? ?? '3 min',
          reason: response['reason'] as String? ?? 'Suggested based on your current state.',
          triggerState: response['triggerState'] as String? ?? stressAssessment.state.name,
          cooldownUntil: response['cooldownUntil'] != null
              ? DateTime.parse(response['cooldownUntil'] as String)
              : null,
          timestamp: DateTime.now(),
        );

        return JitaiDecisionResult(
          isRecommended: true,
          recommendation: rec,
          statusReason: statusReason,
        );
      }
    } catch (_) {
      // Graceful offline fallback to local engine
    }

    // Fallback to local policy engine
    return _localFallback.evaluate(
      stressAssessment: stressAssessment,
      context: context,
      idempotencyKey: key,
      recentInterventions: recentInterventions,
    );
  }
}
