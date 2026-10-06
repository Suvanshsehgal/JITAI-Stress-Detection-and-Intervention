import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../health/models/context_snapshot.dart';
import '../../health/models/data_quality.dart';
import '../models/inference_input.dart';
import '../models/inference_status.dart';
import '../models/stress_assessment.dart';
import '../models/stress_state.dart';
import 'mock_stress_detection_service.dart';
import 'stress_detection_service.dart';

class RemoteStressDetectionService implements StressDetectionService {
  final ApiClient _apiClient;
  final MockStressDetectionService _mockFallback;
  final Uuid _uuid;

  RemoteStressDetectionService({
    required ApiClient apiClient,
    MockStressDetectionService? mockFallback,
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _mockFallback = mockFallback ?? MockStressDetectionService(),
        _uuid = uuid ?? const Uuid();

  @override
  Future<StressAssessment> assessCurrentState(ContextSnapshot snapshot) async {
    final input = InferenceInput.fromContextSnapshot(snapshot);
    return assess(input);
  }

  @override
  Future<StressAssessment> assess(InferenceInput input) async {
    try {
      final payload = {
        'context': input.toJson(),
      };

      final response = await _apiClient.post('/api/v1/stress/assess', payload);

      if (response != null && response is Map<String, dynamic>) {
        return StressAssessment(
          id: response['id'] as String? ?? _uuid.v4(),
          timestamp: response['timestamp'] != null
              ? DateTime.parse(response['timestamp'] as String)
              : DateTime.now(),
          state: StressState.values.firstWhere(
            (e) => e.name == response['state'],
            orElse: () => StressState.unknown,
          ),
          confidence: (response['confidence'] as num?)?.toDouble(),
          inferenceStatus: InferenceStatus.values.firstWhere(
            (e) => e.name == response['inferenceStatus'],
            orElse: () => InferenceStatus.error,
          ),
          dataQuality: DataQualityStatus.values.firstWhere(
            (e) => e.name == response['dataQuality'],
            orElse: () => DataQualityStatus.unavailable,
          ),
          modelVersion: response['modelVersion'] as String? ?? 'stride-probe-remote',
          metadata: Map<String, dynamic>.from(response['metadata'] ?? {}),
          explanation: response['explanation'] != null
              ? Map<String, dynamic>.from(response['explanation'] as Map)
              : null,
        );
      }
    } catch (_) {
      // Gracefully fall back to local mock service if backend is unreachable
    }

    return _mockFallback.assess(input);
  }
}
