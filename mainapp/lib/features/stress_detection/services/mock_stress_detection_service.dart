import 'package:uuid/uuid.dart';
import '../../health/models/context_snapshot.dart';
import '../../health/models/data_quality.dart';
import '../../health/models/health_permission.dart';
import '../models/inference_input.dart';
import '../models/inference_status.dart';
import '../models/stress_assessment.dart';
import '../models/stress_state.dart';
import 'stress_detection_service.dart';

/// Deterministic mock implementation of [StressDetectionService] for development & testing.
///
/// NOTE: Outputs from this service are simulated for UI development and testing only.
/// They do NOT represent real clinical, physiological, or medical conclusions.
class MockStressDetectionService implements StressDetectionService {
  static const String currentMockModelVersion = 'ebb-mock-detector-v1.0';
  final Uuid _uuid;

  // Optional test overrides
  InferenceStatus? forcedStatus;
  StressState? forcedState;
  double? forcedConfidence;
  bool shouldThrowError = false;

  MockStressDetectionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  Future<StressAssessment> assessCurrentState(ContextSnapshot snapshot) async {
    final input = InferenceInput.fromContextSnapshot(snapshot);
    return assess(input);
  }

  @override
  Future<StressAssessment> assess(InferenceInput input) async {
    if (shouldThrowError) {
      return StressAssessment(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.error,
        dataQuality: DataQualityStatus.error,
        modelVersion: currentMockModelVersion,
      );
    }

    if (forcedStatus != null) {
      return StressAssessment(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        state: forcedState ??
            (forcedStatus == InferenceStatus.success
                ? StressState.baseline
                : StressState.unknown),
        confidence: forcedConfidence ??
            (forcedStatus == InferenceStatus.success ? 0.85 : null),
        inferenceStatus: forcedStatus!,
        dataQuality: forcedStatus == InferenceStatus.success
            ? DataQualityStatus.available
            : DataQualityStatus.unavailable,
        modelVersion: currentMockModelVersion,
      );
    }

    // 1. Check for permission requirements
    if (input.isPermissionRequired(HealthDataType.heartRate) &&
        input.isPermissionRequired(HealthDataType.hrv)) {
      return StressAssessment(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.permissionDenied,
        dataQuality: DataQualityStatus.permissionRequired,
        modelVersion: currentMockModelVersion,
      );
    }

    // 2. Check for disabled sources
    if (input.isSourceDisabled(HealthDataType.heartRate) &&
        input.isSourceDisabled(HealthDataType.hrv)) {
      return StressAssessment(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.unavailable,
        dataQuality: DataQualityStatus.disabled,
        modelVersion: currentMockModelVersion,
      );
    }

    // 3. Check for stale data
    if (input.isStale(HealthDataType.heartRate) ||
        input.isStale(HealthDataType.hrv)) {
      return StressAssessment(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.staleData,
        dataQuality: DataQualityStatus.stale,
        modelVersion: currentMockModelVersion,
      );
    }

    // 4. Check if sufficient signals exist
    if (!input.hasSufficientSignals) {
      return StressAssessment(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        state: StressState.unknown,
        inferenceStatus: InferenceStatus.insufficientData,
        dataQuality: DataQualityStatus.noData,
        modelVersion: currentMockModelVersion,
      );
    }

    // 5. Valid signal present -> return deterministic assessment
    return StressAssessment(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      state: forcedState ?? StressState.baseline,
      confidence: forcedConfidence ?? 0.82,
      inferenceStatus: InferenceStatus.success,
      dataQuality: DataQualityStatus.available,
      modelVersion: currentMockModelVersion,
      metadata: const {
        'source': 'mock_deterministic',
        'isSimulated': true,
      },
      explanation: const {
        'summary': 'Signals are consistent with observed baseline resting patterns.',
      },
    );
  }
}
