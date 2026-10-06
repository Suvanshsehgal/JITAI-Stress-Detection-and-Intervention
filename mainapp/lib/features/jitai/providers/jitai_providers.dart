import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../health/models/context_snapshot.dart';
import '../../stress_detection/models/stress_assessment.dart';
import '../models/jitai_decision_result.dart';
import '../models/jitai_recommendation.dart';
import '../models/jitai_user_response.dart';
import '../repositories/jitai_response_repository.dart';
import '../services/jitai_decision_engine.dart';
import '../services/local_jitai_decision_engine.dart';
import '../services/remote_jitai_decision_engine.dart';

/// Configuration flag to switch between real remote backend and local engine.
final useRemoteBackendProvider = StateProvider<bool>((ref) => true);

final jitaiResponseRepositoryProvider = Provider<JitaiResponseRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalJitaiResponseRepository(prefs);
});

final localJitaiDecisionEngineProvider = Provider<LocalJitaiDecisionEngine>((ref) {
  return LocalJitaiDecisionEngine();
});

final remoteJitaiDecisionEngineProvider = Provider<RemoteJitaiDecisionEngine>((ref) {
  final client = ref.watch(apiClientProvider);
  final local = ref.watch(localJitaiDecisionEngineProvider);
  return RemoteJitaiDecisionEngine(apiClient: client, localFallback: local);
});

final jitaiDecisionEngineProvider = Provider<JitaiDecisionEngine>((ref) {
  final useRemote = ref.watch(useRemoteBackendProvider);
  if (useRemote) {
    return ref.watch(remoteJitaiDecisionEngineProvider);
  }
  return ref.watch(localJitaiDecisionEngineProvider);
});

class JitaiRecommendationState {
  final bool isEvaluating;
  final JitaiRecommendation? activeRecommendation;
  final String statusReason;

  const JitaiRecommendationState({
    this.isEvaluating = false,
    this.activeRecommendation,
    this.statusReason = 'idle',
  });

  JitaiRecommendationState copyWith({
    bool? isEvaluating,
    JitaiRecommendation? activeRecommendation,
    String? statusReason,
    bool clearRecommendation = false,
  }) {
    return JitaiRecommendationState(
      isEvaluating: isEvaluating ?? this.isEvaluating,
      activeRecommendation: clearRecommendation
          ? null
          : (activeRecommendation ?? this.activeRecommendation),
      statusReason: statusReason ?? this.statusReason,
    );
  }
}

class JitaiRecommendationNotifier extends StateNotifier<JitaiRecommendationState> {
  final JitaiDecisionEngine _engine;
  final JitaiResponseRepository _repository;
  final Uuid _uuid;

  JitaiRecommendationNotifier({
    required JitaiDecisionEngine engine,
    required JitaiResponseRepository repository,
    Uuid? uuid,
  })  : _engine = engine,
        _repository = repository,
        _uuid = uuid ?? const Uuid(),
        super(const JitaiRecommendationState());

  Future<JitaiDecisionResult> evaluate({
    required StressAssessment stressAssessment,
    required ContextSnapshot context,
    String idempotencyKey = '',
  }) async {
    state = state.copyWith(isEvaluating: true);

    final recentResponses = await _repository.getAllResponses();
    final recentInterventions =
        recentResponses.map((r) => r.interventionId).take(5).toList();

    final result = await _engine.evaluate(
      stressAssessment: stressAssessment,
      context: context,
      idempotencyKey: idempotencyKey,
      recentInterventions: recentInterventions,
    );

    state = state.copyWith(
      isEvaluating: false,
      activeRecommendation: result.recommendation,
      statusReason: result.statusReason,
      clearRecommendation: !result.isRecommended,
    );

    return result;
  }

  Future<void> acceptRecommendation() async {
    final rec = state.activeRecommendation;
    if (rec == null) return;

    final response = JitaiUserResponse(
      id: _uuid.v4(),
      recommendationId: rec.id,
      interventionId: rec.interventionId,
      responseType: JitaiResponseType.accepted,
      timestamp: DateTime.now(),
    );
    await _repository.recordResponse(response);
  }

  Future<void> dismissRecommendation() async {
    final rec = state.activeRecommendation;
    if (rec == null) return;

    final response = JitaiUserResponse(
      id: _uuid.v4(),
      recommendationId: rec.id,
      interventionId: rec.interventionId,
      responseType: JitaiResponseType.dismissed,
      timestamp: DateTime.now(),
    );
    await _repository.recordResponse(response);
    state = state.copyWith(clearRecommendation: true, statusReason: 'dismissed');
  }

  Future<void> declineRecommendation() async {
    final rec = state.activeRecommendation;
    if (rec == null) return;

    final response = JitaiUserResponse(
      id: _uuid.v4(),
      recommendationId: rec.id,
      interventionId: rec.interventionId,
      responseType: JitaiResponseType.declined,
      timestamp: DateTime.now(),
    );
    await _repository.recordResponse(response);
    state = state.copyWith(clearRecommendation: true, statusReason: 'declined');
  }

  Future<void> recordInterventionCompleted(
    String interventionId, {
    String? recommendationId,
    String? postMood,
  }) async {
    final response = JitaiUserResponse(
      id: _uuid.v4(),
      recommendationId: recommendationId,
      interventionId: interventionId,
      responseType: JitaiResponseType.completed,
      timestamp: DateTime.now(),
      postMood: postMood,
    );
    await _repository.recordResponse(response);
  }

  Future<void> recordInterventionAbandoned(
    String interventionId, {
    String? recommendationId,
  }) async {
    final response = JitaiUserResponse(
      id: _uuid.v4(),
      recommendationId: recommendationId,
      interventionId: interventionId,
      responseType: JitaiResponseType.abandoned,
      timestamp: DateTime.now(),
    );
    await _repository.recordResponse(response);
  }
}

final jitaiRecommendationNotifierProvider =
    StateNotifierProvider<JitaiRecommendationNotifier, JitaiRecommendationState>((ref) {
  final engine = ref.watch(jitaiDecisionEngineProvider);
  final repo = ref.watch(jitaiResponseRepositoryProvider);
  return JitaiRecommendationNotifier(
    engine: engine,
    repository: repo,
  );
});
