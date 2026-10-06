enum HealthPermissionStatus {
  notDetermined,
  requested,
  granted,
  denied,
  permanentlyDenied,
  unavailable,
  error,
}

extension HealthPermissionStatusExtension on HealthPermissionStatus {
  String get label {
    switch (this) {
      case HealthPermissionStatus.notDetermined:
        return 'Not requested';
      case HealthPermissionStatus.requested:
        return 'Requested';
      case HealthPermissionStatus.granted:
        return 'Granted';
      case HealthPermissionStatus.denied:
        return 'Denied';
      case HealthPermissionStatus.permanentlyDenied:
        return 'Permanently denied';
      case HealthPermissionStatus.unavailable:
        return 'Unavailable';
      case HealthPermissionStatus.error:
        return 'Error';
    }
  }

  bool get isGranted => this == HealthPermissionStatus.granted;
}

enum HealthDataType {
  heartRate,
  hrv,
  sleep,
  calendar,
  notifications,
}

extension HealthDataTypeExtension on HealthDataType {
  String get displayName {
    switch (this) {
      case HealthDataType.heartRate:
        return 'Heart Rate';
      case HealthDataType.hrv:
        return 'Heart Rate Variability';
      case HealthDataType.sleep:
        return 'Sleep';
      case HealthDataType.calendar:
        return 'Calendar (Busy/Free)';
      case HealthDataType.notifications:
        return 'Notifications';
    }
  }

  String get preferenceKey {
    switch (this) {
      case HealthDataType.heartRate:
      case HealthDataType.hrv:
        return 'hr_hrv';
      case HealthDataType.sleep:
        return 'sleep';
      case HealthDataType.calendar:
        return 'calendar';
      case HealthDataType.notifications:
        return 'notifications';
    }
  }

  String get description {
    switch (this) {
      case HealthDataType.heartRate:
        return 'Periodic heart rate samples from supported wearable or health platform.';
      case HealthDataType.hrv:
        return 'Heart rate variability measurements (RMSSD) to observe resting trends.';
      case HealthDataType.sleep:
        return 'Sleep duration and window to track night-time recovery.';
      case HealthDataType.calendar:
        return 'Checks if you are currently in a busy event window. No titles or details are stored.';
      case HealthDataType.notifications:
        return 'Allows sending supportive nudges and reminders when timely.';
    }
  }
}
