import '../models/inference_input.dart';
import '../models/stress_assessment.dart';

/// Contract for future ML model backends (remote FastAPI inference or local platform adapter).
/// This shields all Flutter feature code from model internals and algorithms.
abstract class StressModelAdapter {
  String get modelVersion;
  Future<StressAssessment> predict(InferenceInput input);
}
