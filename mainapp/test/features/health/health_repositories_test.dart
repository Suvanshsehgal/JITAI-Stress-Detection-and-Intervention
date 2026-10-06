import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mainapp/features/health/models/calendar_context.dart';
import 'package:mainapp/features/health/models/data_quality.dart';
import 'package:mainapp/features/health/models/health_permission.dart';
import 'package:mainapp/features/health/models/heart_rate_sample.dart';
import 'package:mainapp/features/health/models/notification_capability.dart';
import 'package:mainapp/features/health/repositories/calendar_context_repository.dart';
import 'package:mainapp/features/health/repositories/health_data_repository.dart';
import 'package:mainapp/features/health/repositories/health_preferences_repository.dart';
import 'package:mainapp/features/health/services/health_permission_service.dart';
import 'package:mainapp/features/health/services/notification_service.dart';

void main() {
  group('Health Repositories and Services', () {
    late SharedPreferences prefs;
    late LocalHealthPreferencesRepository prefsRepo;
    late MockHealthPermissionService permissionService;
    late MockHealthDataRepository healthRepo;
    late MockCalendarContextRepository calendarRepo;
    late MockNotificationService notificationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'onboardingDataPrefs': ['hr_hrv', 'sleep'],
      });
      prefs = await SharedPreferences.getInstance();
      prefsRepo = LocalHealthPreferencesRepository(prefs);
      permissionService = MockHealthPermissionService();

      healthRepo = MockHealthDataRepository(
        preferences: prefsRepo,
        permissions: permissionService,
      );

      calendarRepo = MockCalendarContextRepository(
        preferences: prefsRepo,
        permissions: permissionService,
      );

      notificationService = MockNotificationService(
        preferences: prefsRepo,
      );
    });

    test('HealthPreferencesRepository reads initial onboarding preferences', () {
      expect(prefsRepo.isSourceEnabled(HealthDataType.heartRate), isTrue);
      expect(prefsRepo.isSourceEnabled(HealthDataType.hrv), isTrue);
      expect(prefsRepo.isSourceEnabled(HealthDataType.sleep), isTrue);
      expect(prefsRepo.isSourceEnabled(HealthDataType.calendar), isFalse);
      expect(prefsRepo.isSourceEnabled(HealthDataType.notifications), isFalse);
    });

    test('HealthPreferencesRepository persists toggled preferences', () async {
      await prefsRepo.setSourceEnabled(HealthDataType.calendar, true);
      expect(prefsRepo.isSourceEnabled(HealthDataType.calendar), isTrue);

      await prefsRepo.setSourceEnabled(HealthDataType.sleep, false);
      expect(prefsRepo.isSourceEnabled(HealthDataType.sleep), isFalse);
    });

    test('HealthPermissionService tracks and updates permissions', () async {
      final status = await permissionService.checkPermission(HealthDataType.heartRate);
      expect(status, HealthPermissionStatus.notDetermined);

      final requested = await permissionService.requestPermission(HealthDataType.heartRate);
      expect(requested, HealthPermissionStatus.granted);

      final updated = await permissionService.checkPermission(HealthDataType.heartRate);
      expect(updated, HealthPermissionStatus.granted);

      await permissionService.openSettings();
      expect(permissionService.settingsOpened, isTrue);
    });

    test('HealthDataRepository returns disabled status when preference is off', () async {
      // Calendar and notifications are disabled
      final status = await healthRepo.getSourceStatus(HealthDataType.calendar);
      expect(status, DataQualityStatus.disabled);
    });

    test('HealthDataRepository returns permissionRequired when not granted', () async {
      // hr_hrv is enabled in prefs, but permission not yet granted
      final status = await healthRepo.getSourceStatus(HealthDataType.heartRate);
      expect(status, DataQualityStatus.permissionRequired);

      final hr = await healthRepo.getLatestHeartRate();
      expect(hr, isNull);
    });

    test('HealthDataRepository returns noData and null when no wearable is connected (NO fake data)', () async {
      // Grant permission
      await permissionService.requestPermission(HealthDataType.heartRate);

      final status = await healthRepo.getSourceStatus(HealthDataType.heartRate);
      expect(status, DataQualityStatus.noData);

      // Must be null! No fake physiological values should be invented
      final hr = await healthRepo.getLatestHeartRate();
      expect(hr, isNull);

      final hrv = await healthRepo.getLatestHRV();
      expect(hrv, isNull);

      final sleep = await healthRepo.getLatestSleepSession();
      expect(sleep, isNull);
    });

    test('HealthDataRepository returns real samples when explicitly provided', () async {
      await permissionService.requestPermission(HealthDataType.heartRate);
      final sample = HeartRateSample(
        bpm: 75.0,
        timestamp: DateTime.now(),
      );
      healthRepo.setDemoHeartRate(sample);

      final status = await healthRepo.getSourceStatus(HealthDataType.heartRate);
      expect(status, DataQualityStatus.available);

      final hr = await healthRepo.getLatestHeartRate();
      expect(hr, isNotNull);
      expect(hr!.bpm, 75.0);
    });

    test('CalendarContextRepository reflects disabled and privacy-preserving states', () async {
      // Initially disabled
      var context = await calendarRepo.getCalendarContext();
      expect(context.quality, DataQualityStatus.disabled);
      expect(context.state, CalendarBusyState.unknown);

      // Enable in preferences
      await prefsRepo.setSourceEnabled(HealthDataType.calendar, true);

      // Permission needed
      context = await calendarRepo.getCalendarContext();
      expect(context.quality, DataQualityStatus.permissionRequired);

      // Grant permission
      await permissionService.requestPermission(HealthDataType.calendar);
      calendarRepo.setMockState(CalendarBusyState.free);

      context = await calendarRepo.getCalendarContext();
      expect(context.quality, DataQualityStatus.available);
      expect(context.state, CalendarBusyState.free);
    });

    test('NotificationService respects preferences and reports capability', () async {
      // Initially notifications is disabled in prefs
      var cap = await notificationService.getNotificationCapability();
      expect(cap.quality, DataQualityStatus.disabled);
      expect(cap.status, NotificationCapabilityStatus.denied);

      // Enable notifications
      await prefsRepo.setSourceEnabled(HealthDataType.notifications, true);
      cap = await notificationService.getNotificationCapability();
      expect(cap.quality, DataQualityStatus.available);
      expect(cap.status, NotificationCapabilityStatus.enabled);
    });
  });
}
