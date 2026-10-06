import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mainapp/core/network/api_client.dart';
import 'package:mainapp/features/health/models/calendar_context.dart';
import 'package:mainapp/features/health/models/context_snapshot.dart';
import 'package:mainapp/features/health/models/heart_rate_sample.dart';
import 'package:mainapp/features/health/models/hrv_sample.dart';
import 'package:mainapp/features/stress_detection/models/inference_status.dart';
import 'package:mainapp/features/stress_detection/models/stress_state.dart';
import 'package:mainapp/features/stress_detection/services/remote_stress_detection_service.dart';

void main() {
  group('RemoteStressDetectionService', () {
    test('calls backend API and parses assessment correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/stress/assess');
        expect(request.method, 'POST');
        final decoded = jsonDecode(request.body);
        expect(decoded['context']['heartRateBpm'], 82.0);
        expect(decoded['context']['hrvRmssdMs'], 25.0);

        return http.Response(
          jsonEncode({
            'state': 'elevated',
            'inferenceStatus': 'success',
            'confidence': 0.88,
            'timestamp': DateTime.now().toIso8601String(),
            'modelVersion': 'stride-probe-composite-v1.0',
            'dataQuality': 'available',
            'explanation': {'factors': ['Low HRV', 'Elevated HR']},
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final service = RemoteStressDetectionService(apiClient: apiClient);

      final context = ContextSnapshot(
        timestamp: DateTime.now(),
        heartRate: HeartRateSample(
          timestamp: DateTime.now(),
          bpm: 82.0,
        ),
        hrv: HRVSample(
          timestamp: DateTime.now(),
          rmssdMs: 25.0,
        ),
      );

      final assessment = await service.assessCurrentState(context);

      expect(assessment.state, StressState.elevated);
      expect(assessment.inferenceStatus, InferenceStatus.success);
      expect(assessment.confidence, 0.88);
      expect(assessment.modelVersion, 'stride-probe-composite-v1.0');
      expect(assessment.explanation?['factors'], contains('Low HRV'));
    });

    test('falls back gracefully to mock assessment on network failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final service = RemoteStressDetectionService(apiClient: apiClient);

      final context = ContextSnapshot(
        timestamp: DateTime.now(),
        calendar: CalendarContext(
          state: CalendarBusyState.free,
          timestamp: DateTime.now(),
        ),
      );

      // Should not throw, should fallback to mock
      final assessment = await service.assessCurrentState(context);

      expect(assessment, isNotNull);
      expect(assessment.modelVersion, contains('mock'));
    });
  });
}
