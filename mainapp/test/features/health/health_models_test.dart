import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/features/health/models/calendar_context.dart';
import 'package:mainapp/features/health/models/context_snapshot.dart';
import 'package:mainapp/features/health/models/data_quality.dart';
import 'package:mainapp/features/health/models/heart_rate_sample.dart';
import 'package:mainapp/features/health/models/hrv_sample.dart';
import 'package:mainapp/features/health/models/notification_capability.dart';
import 'package:mainapp/features/health/models/sleep_session.dart';

void main() {
  group('Health & Context Domain Models', () {
    test('HeartRateSample serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final sample = HeartRateSample(
        bpm: 72.5,
        timestamp: now,
        quality: DataQualityStatus.available,
      );

      final json = sample.toJson();
      final fromJson = HeartRateSample.fromJson(json);

      expect(fromJson.bpm, 72.5);
      expect(fromJson.timestamp, now);
      expect(fromJson.quality, DataQualityStatus.available);
      expect(fromJson, equals(sample));
    });

    test('HRVSample serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final sample = HRVSample(
        rmssdMs: 48.2,
        timestamp: now,
        quality: DataQualityStatus.available,
      );

      final json = sample.toJson();
      final fromJson = HRVSample.fromJson(json);

      expect(fromJson.rmssdMs, 48.2);
      expect(fromJson.timestamp, now);
      expect(fromJson, equals(sample));
    });

    test('SleepSession formats duration and serializes correctly', () {
      final start = DateTime(2026, 10, 5, 23, 0);
      final end = DateTime(2026, 10, 6, 7, 30);
      final session = SleepSession(startTime: start, endTime: end);

      expect(session.duration, const Duration(hours: 8, minutes: 30));
      expect(session.formattedDuration, '8h 30m');

      final json = session.toJson();
      final fromJson = SleepSession.fromJson(json);
      expect(fromJson.duration.inMinutes, 510);
      expect(fromJson.formattedDuration, '8h 30m');
    });

    test('CalendarContext handles busy, free, unknown and preserves privacy', () {
      final now = DateTime(2026, 10, 6, 14, 0);
      final cal = CalendarContext(
        state: CalendarBusyState.busy,
        timestamp: now,
        quality: DataQualityStatus.available,
      );

      expect(cal.state.label, 'Busy');
      final json = cal.toJson();
      final fromJson = CalendarContext.fromJson(json);
      expect(fromJson.state, CalendarBusyState.busy);

      // Verify no event details exist in JSON
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('attendees'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });

    test('NotificationCapability reflects enabled and denied states', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final notif = NotificationCapability(
        status: NotificationCapabilityStatus.enabled,
        lastChecked: now,
        quality: DataQualityStatus.available,
      );

      expect(notif.status.isCapable, isTrue);
      expect(notif.status.label, 'Enabled');

      final json = notif.toJson();
      final fromJson = NotificationCapability.fromJson(json);
      expect(fromJson.status, NotificationCapabilityStatus.enabled);
    });

    test('DataFreshness computes freshness window', () {
      final fresh = DataFreshness(
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        status: DataQualityStatus.available,
      );
      expect(fresh.isFresh(maxAge: const Duration(minutes: 30)), isTrue);

      final stale = DataFreshness(
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        status: DataQualityStatus.available,
      );
      expect(stale.isFresh(maxAge: const Duration(minutes: 30)), isFalse);

      final unavailable = DataFreshness(
        lastUpdated: DateTime.now(),
        status: DataQualityStatus.unavailable,
      );
      expect(unavailable.isFresh(), isFalse);
    });

    test('ContextSnapshot supports missing signals and empty states without crashing', () {
      final empty = ContextSnapshot.empty();
      expect(empty.hasAnyHealthData, isFalse);
      expect(empty.heartRate, isNull);
      expect(empty.hrv, isNull);
      expect(empty.sleep, isNull);
      expect(empty.calendar, isNull);
      expect(empty.notificationCapability, isNull);

      // Serialization of empty snapshot
      final json = empty.toJson();
      final fromJson = ContextSnapshot.fromJson(json);
      expect(fromJson.hasAnyHealthData, isFalse);
      expect(fromJson.heartRate, isNull);
    });

    test('ContextSnapshot with populated data serializes cleanly', () {
      final now = DateTime(2026, 10, 6, 10, 0);
      final snapshot = ContextSnapshot(
        timestamp: now,
        heartRate: HeartRateSample(bpm: 70, timestamp: now),
        calendar: CalendarContext(state: CalendarBusyState.free, timestamp: now),
        recentMood: 4,
        recentInterventionId: 'box-breathing',
      );

      expect(snapshot.hasHeartRate, isTrue);
      expect(snapshot.hasAnyHealthData, isTrue);
      expect(snapshot.calendar?.state, CalendarBusyState.free);

      final json = snapshot.toJson();
      final fromJson = ContextSnapshot.fromJson(json);
      expect(fromJson.heartRate?.bpm, 70);
      expect(fromJson.calendar?.state, CalendarBusyState.free);
      expect(fromJson.recentMood, 4);
    });
  });
}
