import '../../../core/network/api_client.dart';
import '../../jitai/repositories/jitai_response_repository.dart';

enum SyncStateStatus {
  idle,
  syncing,
  success,
  offline,
  failed,
}

class SyncService {
  final ApiClient _apiClient;
  final JitaiResponseRepository _repository;

  SyncService({
    required ApiClient apiClient,
    required JitaiResponseRepository repository,
  })  : _apiClient = apiClient,
        _repository = repository;

  Future<int> syncPendingResponses() async {
    final pending = await _repository.getPendingResponses();
    if (pending.isEmpty) {
      return 0;
    }

    try {
      final itemsPayload = pending.map((item) => item.toJson()).toList();
      final res = await _apiClient.post('/api/v1/sync/interventions', {
        'items': itemsPayload,
      });

      if (res != null && res is Map<String, dynamic>) {
        final syncedIds = pending.map((p) => p.id).toList();
        await _repository.markAsSynced(syncedIds);
        return syncedIds.length;
      }
    } catch (_) {
      // Offline or network error
      return 0;
    }

    return 0;
  }
}
