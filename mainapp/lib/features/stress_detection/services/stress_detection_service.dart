import '../../health/models/context_snapshot.dart';
import '../models/inference_input.dart';
import '../models/stress_assessment.dart';

abstract class StressDetectionService {
  Future<StressAssessment> assess(InferenceInput input);
  Future<StressAssessment> assessCurrentState(ContextSnapshot snapshot);
}
