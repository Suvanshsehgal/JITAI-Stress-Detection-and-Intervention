import 'package:uuid/uuid.dart';
import '../../health/models/calendar_context.dart';
import '../../health/models/context_snapshot.dart';
import '../../stress_detection/models/stress_assessment.dart';
import '../../stress_detection/models/stress_state.dart';
import '../models/jitai_decision_result.dart';
import '../models/jitai_recommendation.dart';
import 'jitai_decision_engine.dart';

class LocalJitaiDecisionEngine implements JitaiDecisionEngine {
  final Uuid _uuid;
  final Duration cooldownDuration;
  DateTime? _lastRecommendationTime;
  final Map<String, JitaiDecisionResult> _idempotencyCache = {};

  LocalJitaiDecisionEngine({
    Uuid? uuid,
    this.cooldownDuration = const Duration(minutes: 15),
  }) : _uuid = uuid ?? const Uuid();

  void resetCooldown() {
    _lastRecommendationTime = null;
    _idempotencyCache.clear();
  }

  @override
  Future<JitaiDecisionResult> evaluate({
    required StressAssessment stressAssessment,
    required ContextSnapshot context,
    String idempotencyKey = '',
    List<String> recentInterventions = const [],
  }) async {
    // 1. Idempotency check
    if (idempotencyKey.isNotEmpty && _idempotencyCache.containsKey(idempotencyKey)) {
      return _idempotencyCache[idempotencyKey]!;
    }

    // 2. Check assessment success
    if (!stressAssessment.isSuccessful) {
      final res = JitaiDecisionResult.notRecommendedInsufficientData;
      if (idempotencyKey.isNotEmpty) _idempotencyCache[idempotencyKey] = res;
      return res;
    }

    // 3. Check calendar context: suppress if busy
    if (context.calendar?.state == CalendarBusyState.busy) {
      final res = JitaiDecisionResult.notRecommendedBusy;
      if (idempotencyKey.isNotEmpty) _idempotencyCache[idempotencyKey] = res;
      return res;
    }

    // 4. Cooldown check
    final now = DateTime.now();
    if (_lastRecommendationTime != null &&
        now.difference(_lastRecommendationTime!) < cooldownDuration) {
      final res = JitaiDecisionResult.notRecommendedCooldown;
      if (idempotencyKey.isNotEmpty) _idempotencyCache[idempotencyKey] = res;
      return res;
    }

    // 5. Check stress state: steady does not require intervention
    if (stressAssessment.state == StressState.baseline) {
      final res = JitaiDecisionResult.notRecommendedSteady;
      if (idempotencyKey.isNotEmpty) _idempotencyCache[idempotencyKey] = res;
      return res;
    }

    // 6. Issue recommendation for elevated or high stress
    _lastRecommendationTime = now;
    final cooldownUntil = now.add(cooldownDuration);

    String interventionId;
    String title;
    String description;
    String duration;
    String reason;

    if (stressAssessment.state == StressState.high) {
      interventionId = 'box-breathing';
      title = 'Box Breathing';
      description = 'A steady 4-4-4-4 rhythm to regulate physiological activation.';
      duration = '3 min';
      reason = 'Your recent signals show high activation. Taking 3 minutes can restore balance.';
    } else {
      if (recentInterventions.contains('focus-reset')) {
        interventionId = 'grounding-54321';
        title = '5-4-3-2-1 Grounding';
        description = 'Engage your senses to re-anchor into the present moment.';
        duration = '5 min';
        reason = 'A gentle sensory reset to clear cognitive overload.';
      } else {
        interventionId = 'focus-reset';
        title = 'Focus Reset';
        description = 'Step back and recalibrate attention.';
        duration = '2 min';
        reason = 'A quick pause to steady your focus.';
      }
    }

    final recommendation = JitaiRecommendation(
      id: _uuid.v4(),
      interventionId: interventionId,
      title: title,
      description: description,
      duration: duration,
      reason: reason,
      triggerState: stressAssessment.state.name,
      cooldownUntil: cooldownUntil,
      timestamp: now,
    );

    final result = JitaiDecisionResult(
      isRecommended: true,
      recommendation: recommendation,
      statusReason: 'recommended',
    );

    if (idempotencyKey.isNotEmpty) {
      _idempotencyCache[idempotencyKey] = result;
    }

    return result;
  }
}
