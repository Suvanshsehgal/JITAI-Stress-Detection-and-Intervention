import '../models/data_quality.dart';
import '../models/health_permission.dart';
import '../models/heart_rate_sample.dart';
import '../models/hrv_sample.dart';
import '../models/sleep_session.dart';
import '../services/health_permission_service.dart';
import 'health_preferences_repository.dart';

abstract class HealthDataRepository {
  Future<HeartRateSample?> getLatestHeartRate();
  Future<HRVSample?> getLatestHRV();
  Future<SleepSession?> getLatestSleepSession();
  Future<DataQualityStatus> getSourceStatus(HealthDataType type);
}

class MockHealthDataRepository implements HealthDataRepository {
  final HealthPreferencesRepository _preferences;
  final HealthPermissionService _permissions;

  HeartRateSample? _demoHeartRate;
  HRVSample? _demoHRV;
  SleepSession? _demoSleep;

  MockHealthDataRepository({
    required HealthPreferencesRepository preferences,
    required HealthPermissionService permissions,
    HeartRateSample? demoHeartRate,
    HRVSample? demoHRV,
    SleepSession? demoSleep,
  })  : _preferences = preferences,
        _permissions = permissions,
        _demoHeartRate = demoHeartRate,
        _demoHRV = demoHRV,
        _demoSleep = demoSleep;

  void setDemoHeartRate(HeartRateSample? sample) => _demoHeartRate = sample;
  void setDemoHRV(HRVSample? sample) => _demoHRV = sample;
  void setDemoSleep(SleepSession? session) => _demoSleep = session;

  @override
  Future<DataQualityStatus> getSourceStatus(HealthDataType type) async {
    if (!_preferences.isSourceEnabled(type)) {
      return DataQualityStatus.disabled;
    }

    final permission = await _permissions.checkPermission(type);
    if (!permission.isGranted) {
      return DataQualityStatus.permissionRequired;
    }

    switch (type) {
      case HealthDataType.heartRate:
        return _demoHeartRate != null
            ? DataQualityStatus.available
            : DataQualityStatus.noData;
      case HealthDataType.hrv:
        return _demoHRV != null
            ? DataQualityStatus.available
            : DataQualityStatus.noData;
      case HealthDataType.sleep:
        return _demoSleep != null
            ? DataQualityStatus.available
            : DataQualityStatus.noData;
      case HealthDataType.calendar:
      case HealthDataType.notifications:
        return DataQualityStatus.available;
    }
  }

  @override
  Future<HeartRateSample?> getLatestHeartRate() async {
    final status = await getSourceStatus(HealthDataType.heartRate);
    if (status != DataQualityStatus.available) {
      return null;
    }
    return _demoHeartRate;
  }

  @override
  Future<HRVSample?> getLatestHRV() async {
    final status = await getSourceStatus(HealthDataType.hrv);
    if (status != DataQualityStatus.available) {
      return null;
    }
    return _demoHRV;
  }

  @override
  Future<SleepSession?> getLatestSleepSession() async {
    final status = await getSourceStatus(HealthDataType.sleep);
    if (status != DataQualityStatus.available) {
      return null;
    }
    return _demoSleep;
  }
}
