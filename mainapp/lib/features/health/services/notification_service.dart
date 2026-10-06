import '../models/data_quality.dart';
import '../models/health_permission.dart';
import '../models/notification_capability.dart';
import '../repositories/health_preferences_repository.dart';

abstract class NotificationService {
  Future<NotificationCapability> getNotificationCapability();
  Future<NotificationCapabilityStatus> requestPermission();
}

class MockNotificationService implements NotificationService {
  final HealthPreferencesRepository _preferences;
  NotificationCapabilityStatus _mockStatus;

  MockNotificationService({
    required HealthPreferencesRepository preferences,
    NotificationCapabilityStatus mockStatus = NotificationCapabilityStatus.enabled,
  })  : _preferences = preferences,
        _mockStatus = mockStatus;

  void setMockStatus(NotificationCapabilityStatus status) {
    _mockStatus = status;
  }

  @override
  Future<NotificationCapability> getNotificationCapability() async {
    final isEnabled = _preferences.isSourceEnabled(HealthDataType.notifications);
    if (!isEnabled) {
      return NotificationCapability(
        status: NotificationCapabilityStatus.denied,
        lastChecked: DateTime.now(),
        quality: DataQualityStatus.disabled,
      );
    }

    return NotificationCapability(
      status: _mockStatus,
      lastChecked: DateTime.now(),
      quality: _mockStatus == NotificationCapabilityStatus.enabled
          ? DataQualityStatus.available
          : DataQualityStatus.permissionRequired,
    );
  }

  @override
  Future<NotificationCapabilityStatus> requestPermission() async {
    _mockStatus = NotificationCapabilityStatus.enabled;
    return NotificationCapabilityStatus.enabled;
  }
}
