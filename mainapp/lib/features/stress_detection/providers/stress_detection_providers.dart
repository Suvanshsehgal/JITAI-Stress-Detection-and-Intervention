import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../health/providers/health_providers.dart';
import '../models/stress_assessment.dart';
import '../repositories/stress_assessment_repository.dart';
import '../services/mock_stress_detection_service.dart';
import '../services/stress_detection_service.dart';

final stressAssessmentRepositoryProvider =
    Provider<StressAssessmentRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStressAssessmentRepository(prefs);
});

final stressDetectionServiceProvider = Provider<StressDetectionService>((ref) {
  return MockStressDetectionService();
});

class StressDetectionState {
  final bool isLoading;
  final StressAssessment? currentAssessment;
  final String? errorMessage;
  final int requestToken;

  const StressDetectionState({
    this.isLoading = false,
    this.currentAssessment,
    this.errorMessage,
    this.requestToken = 0,
  });

  StressDetectionState copyWith({
    bool? isLoading,
    StressAssessment? currentAssessment,
    String? errorMessage,
    int? requestToken,
    bool clearAssessment = false,
  }) {
    return StressDetectionState(
      isLoading: isLoading ?? this.isLoading,
      currentAssessment:
          clearAssessment ? null : (currentAssessment ?? this.currentAssessment),
      errorMessage: errorMessage,
      requestToken: requestToken ?? this.requestToken,
    );
  }
}

class StressDetectionNotifier extends StateNotifier<StressDetectionState> {
  final StressDetectionService _service;
  final StressAssessmentRepository _repository;
  final Ref _ref;

  StressDetectionNotifier({
    required StressDetectionService service,
    required StressAssessmentRepository repository,
    required Ref ref,
  })  : _service = service,
        _repository = repository,
        _ref = ref,
        super(const StressDetectionState()) {
    _loadLatestAssessment();
  }

  Future<void> _loadLatestAssessment() async {
    final latest = await _repository.getLatestAssessment();
    if (latest != null && mounted) {
      state = state.copyWith(currentAssessment: latest);
    }
  }

  /// Explicit, lifecycle-safe assessment request.
  /// Prevents concurrent duplicate calls and protects against stale asynchronous results.
  Future<StressAssessment?> assessCurrentState() async {
    if (state.isLoading) {
      // Prevent duplicate in-flight requests
      return null;
    }

    final currentToken = state.requestToken + 1;
    state = state.copyWith(isLoading: true, requestToken: currentToken);

    try {
      final snapshot = await _ref.read(contextSnapshotProvider.future);
      final assessment = await _service.assessCurrentState(snapshot);

      // Check if another request was launched while this one was pending
      if (!mounted || state.requestToken != currentToken) {
        return null;
      }

      // Persist only successful assessments
      if (assessment.isSuccessful) {
        await _repository.saveAssessment(assessment);
      }

      state = state.copyWith(
        isLoading: false,
        currentAssessment: assessment,
      );

      return assessment;
    } catch (_) {
      if (!mounted || state.requestToken != currentToken) {
        return null;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to evaluate signals at this time.',
      );
      return null;
    }
  }

  void reset() {
    state = const StressDetectionState();
  }
}

final stressDetectionProvider =
    StateNotifierProvider<StressDetectionNotifier, StressDetectionState>((ref) {
  final service = ref.watch(stressDetectionServiceProvider);
  final repo = ref.watch(stressAssessmentRepositoryProvider);
  return StressDetectionNotifier(
    service: service,
    repository: repo,
    ref: ref,
  );
});

final stressAssessmentHistoryProvider =
    FutureProvider<List<StressAssessment>>((ref) async {
  final repo = ref.watch(stressAssessmentRepositoryProvider);
  // Re-read when current assessment changes
  ref.watch(stressDetectionProvider);
  return repo.getAssessmentHistory();
});
