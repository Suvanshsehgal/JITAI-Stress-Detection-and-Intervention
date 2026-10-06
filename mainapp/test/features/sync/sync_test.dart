import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mainapp/core/network/api_client.dart';
import 'package:mainapp/features/jitai/models/jitai_user_response.dart';
import 'package:mainapp/features/jitai/repositories/jitai_response_repository.dart';
import 'package:mainapp/features/sync/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SyncService', () {
    late LocalJitaiResponseRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = LocalJitaiResponseRepository(prefs);
    });

    test('syncPendingResponses pushes records to backend and updates local status', () async {
      // Record a response
      await repository.recordResponse(JitaiUserResponse(
        id: 'rec-test-1',
        recommendationId: 'rec-test-1',
        interventionId: 'box-breathing',
        responseType: JitaiResponseType.accepted,
        timestamp: DateTime.now(),
      ));

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/sync/interventions');
        expect(request.method, 'POST');
        final decoded = jsonDecode(request.body);
        expect(decoded['items'].length, 1);
        expect(decoded['items'][0]['id'], 'rec-test-1');

        return http.Response(
          jsonEncode({
            'syncedCount': 1,
            'message': 'Sync successful',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final syncService = SyncService(
        apiClient: apiClient,
        repository: repository,
      );

      final count = await syncService.syncPendingResponses();

      expect(count, 1);

      final pending = await repository.getPendingResponses();
      expect(pending, isEmpty);
    });

    test('syncPendingResponses does not make network request if no pending items', () async {
      var called = false;
      final mockClient = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final syncService = SyncService(
        apiClient: apiClient,
        repository: repository,
      );

      final count = await syncService.syncPendingResponses();

      expect(count, 0);
      expect(called, isFalse);
    });
  });
}
