import '../models/health_permission.dart';

abstract class HealthPermissionService {
  Future<HealthPermissionStatus> checkPermission(HealthDataType type);
  Future<HealthPermissionStatus> requestPermission(HealthDataType type);
  Future<void> openSettings();
}

class MockHealthPermissionService implements HealthPermissionService {
  final Map<HealthDataType, HealthPermissionStatus> _permissionStates;
  bool settingsOpened = false;

  MockHealthPermissionService({
    Map<HealthDataType, HealthPermissionStatus>? initialStates,
  }) : _permissionStates = initialStates != null
            ? Map<HealthDataType, HealthPermissionStatus>.from(initialStates)
            : {
                HealthDataType.heartRate: HealthPermissionStatus.notDetermined,
                HealthDataType.hrv: HealthPermissionStatus.notDetermined,
                HealthDataType.sleep: HealthPermissionStatus.notDetermined,
                HealthDataType.calendar: HealthPermissionStatus.notDetermined,
                HealthDataType.notifications: HealthPermissionStatus.notDetermined,
              };

  @override
  Future<HealthPermissionStatus> checkPermission(HealthDataType type) async {
    return _permissionStates[type] ?? HealthPermissionStatus.notDetermined;
  }

  @override
  Future<HealthPermissionStatus> requestPermission(HealthDataType type) async {
    final current = _permissionStates[type] ?? HealthPermissionStatus.notDetermined;
    if (current == HealthPermissionStatus.permanentlyDenied) {
      return HealthPermissionStatus.permanentlyDenied;
    }
    // Simulate user granting permission on request
    _permissionStates[type] = HealthPermissionStatus.granted;
    return HealthPermissionStatus.granted;
  }

  void setPermission(HealthDataType type, HealthPermissionStatus status) {
    _permissionStates[type] = status;
  }

  @override
  Future<void> openSettings() async {
    settingsOpened = true;
  }
}
