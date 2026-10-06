import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../insights/providers/mood_provider.dart';
import '../../toolbox/providers/session_history_provider.dart';
import '../models/context_snapshot.dart';
import '../models/data_quality.dart';
import '../models/health_permission.dart';
import '../repositories/calendar_context_repository.dart';
import '../repositories/health_data_repository.dart';
import '../repositories/health_preferences_repository.dart';
import '../services/health_permission_service.dart';
import '../services/notification_service.dart';

// --- Services & Repositories Providers ---

final healthPreferencesRepositoryProvider =
    Provider<HealthPreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalHealthPreferencesRepository(prefs);
});

final healthPermissionServiceProvider =
    Provider<HealthPermissionService>((ref) {
  return MockHealthPermissionService();
});

final healthDataRepositoryProvider = Provider<HealthDataRepository>((ref) {
  final prefs = ref.watch(healthPreferencesRepositoryProvider);
  final permissions = ref.watch(healthPermissionServiceProvider);
  return MockHealthDataRepository(
    preferences: prefs,
    permissions: permissions,
  );
});

final calendarContextRepositoryProvider =
    Provider<CalendarContextRepository>((ref) {
  final prefs = ref.watch(healthPreferencesRepositoryProvider);
  final permissions = ref.watch(healthPermissionServiceProvider);
  return MockCalendarContextRepository(
    preferences: prefs,
    permissions: permissions,
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final prefs = ref.watch(healthPreferencesRepositoryProvider);
  return MockNotificationService(preferences: prefs);
});

// --- State Notifier for Health Preferences ---

class HealthPreferencesNotifier extends StateNotifier<Set<String>> {
  final HealthPreferencesRepository _repository;

  HealthPreferencesNotifier(this._repository)
      : super(_repository.getAllEnabledPreferenceIds());

  bool isEnabled(HealthDataType type) {
    return state.contains(type.preferenceKey);
  }

  Future<void> togglePreference(HealthDataType type) async {
    final currentlyEnabled = isEnabled(type);
    await setPreference(type, !currentlyEnabled);
  }

  Future<void> setPreference(HealthDataType type, bool enabled) async {
    final updated = Set<String>.from(state);
    if (enabled) {
      updated.add(type.preferenceKey);
    } else {
      updated.remove(type.preferenceKey);
    }
    await _repository.setAllEnabledPreferenceIds(updated);
    state = updated;
  }
}

final healthPreferencesProvider =
    StateNotifierProvider<HealthPreferencesNotifier, Set<String>>((ref) {
  final repo = ref.watch(healthPreferencesRepositoryProvider);
  return HealthPreferencesNotifier(repo);
});

// --- Health Overview Provider ---

class HealthSourceStatus {
  final HealthDataType type;
  final DataQualityStatus status;
  final HealthPermissionStatus permissionStatus;
  final bool isEnabled;

  const HealthSourceStatus({
    required this.type,
    required this.status,
    required this.permissionStatus,
    required this.isEnabled,
  });
}

final healthOverviewProvider =
    FutureProvider<Map<HealthDataType, HealthSourceStatus>>((ref) async {
  // Watch preferences to reactively rebuild when toggled
  ref.watch(healthPreferencesProvider);

  final healthRepo = ref.watch(healthDataRepositoryProvider);
  final permissionService = ref.watch(healthPermissionServiceProvider);
  final prefsRepo = ref.watch(healthPreferencesRepositoryProvider);
  final calendarRepo = ref.watch(calendarContextRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  final result = <HealthDataType, HealthSourceStatus>{};

  for (final type in HealthDataType.values) {
    final isEnabled = prefsRepo.isSourceEnabled(type);
    final permission = await permissionService.checkPermission(type);
    DataQualityStatus status;

    if (!isEnabled) {
      status = DataQualityStatus.disabled;
    } else if (!permission.isGranted) {
      status = DataQualityStatus.permissionRequired;
    } else {
      switch (type) {
        case HealthDataType.heartRate:
        case HealthDataType.hrv:
        case HealthDataType.sleep:
          status = await healthRepo.getSourceStatus(type);
          break;
        case HealthDataType.calendar:
          status = await calendarRepo.getStatus();
          break;
        case HealthDataType.notifications:
          final cap = await notificationService.getNotificationCapability();
          status = cap.quality;
          break;
      }
    }

    result[type] = HealthSourceStatus(
      type: type,
      status: status,
      permissionStatus: permission,
      isEnabled: isEnabled,
    );
  }

  return result;
});

// --- ContextSnapshot Provider ---

final contextSnapshotProvider = FutureProvider<ContextSnapshot>((ref) async {
  // Watch dependencies so snapshot updates reactively
  ref.watch(healthPreferencesProvider);
  final moods = ref.watch(moodProvider);
  final sessions = ref.watch(sessionHistoryProvider);

  final healthRepo = ref.watch(healthDataRepositoryProvider);
  final calendarRepo = ref.watch(calendarContextRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  // Health data
  final hr = await healthRepo.getLatestHeartRate();
  final hrv = await healthRepo.getLatestHRV();
  final sleep = await healthRepo.getLatestSleepSession();

  // Context
  final calendar = await calendarRepo.getCalendarContext();
  final notificationCap = await notificationService.getNotificationCapability();

  // Mood & Intervention
  final recentMood = moods.isNotEmpty ? moods.first.moodValue : null;
  final recentInterventionId =
      sessions.isNotEmpty ? sessions.first.interventionId : null;

  // Source statuses
  final sourceStatuses = <HealthDataType, DataQualityStatus>{};
  for (final type in HealthDataType.values) {
    sourceStatuses[type] = await healthRepo.getSourceStatus(type);
  }

  return ContextSnapshot(
    timestamp: DateTime.now(),
    heartRate: hr,
    hrv: hrv,
    sleep: sleep,
    calendar: calendar,
    notificationCapability: notificationCap,
    recentMood: recentMood,
    recentInterventionId: recentInterventionId,
    sourceStatuses: sourceStatuses,
  );
});
