import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../jitai/providers/jitai_providers.dart';
import '../services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final repo = ref.watch(jitaiResponseRepositoryProvider);
  return SyncService(
    apiClient: apiClient,
    repository: repo,
  );
});

class SyncNotifier extends StateNotifier<SyncStateStatus> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(SyncStateStatus.idle);

  Future<int> syncNow() async {
    state = SyncStateStatus.syncing;
    try {
      final count = await _syncService.syncPendingResponses();
      state = SyncStateStatus.success;
      return count;
    } catch (_) {
      state = SyncStateStatus.failed;
      return 0;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncStateStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return SyncNotifier(service);
});
