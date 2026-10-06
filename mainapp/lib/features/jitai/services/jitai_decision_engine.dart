import '../../health/models/context_snapshot.dart';
import '../../stress_detection/models/stress_assessment.dart';
import '../models/jitai_decision_result.dart';

abstract class JitaiDecisionEngine {
  Future<JitaiDecisionResult> evaluate({
    required StressAssessment stressAssessment,
    required ContextSnapshot context,
    String idempotencyKey = '',
    List<String> recentInterventions = const [],
  });
}
