enum InferenceStatus {
  success,
  insufficientData,
  unavailable,
  staleData,
  permissionDenied,
  error,
}

extension InferenceStatusExtension on InferenceStatus {
  String get label {
    switch (this) {
      case InferenceStatus.success:
        return 'Assessment Complete';
      case InferenceStatus.insufficientData:
        return 'More Information Needed';
      case InferenceStatus.unavailable:
        return 'Signals Unavailable';
      case InferenceStatus.staleData:
        return 'Signals Need Refresh';
      case InferenceStatus.permissionDenied:
        return 'Permission Required';
      case InferenceStatus.error:
        return 'Unable to Assess';
    }
  }

  String get userMessage {
    switch (this) {
      case InferenceStatus.success:
        return 'Estimated pattern assessment ready based on available observations.';
      case InferenceStatus.insufficientData:
        return 'More information is needed before Ebb can make an assessment. Keep checking in daily to establish your baseline.';
      case InferenceStatus.unavailable:
        return 'Context signals from your wearable or device are currently unavailable.';
      case InferenceStatus.staleData:
        return 'Recent data has not been updated lately. Reconnecting your data source will update readings.';
      case InferenceStatus.permissionDenied:
        return 'Ebb needs permission to access contextual data before evaluating patterns.';
      case InferenceStatus.error:
        return 'Something went wrong while evaluating signals. Please try again later.';
    }
  }

  bool get isSuccess => this == InferenceStatus.success;
}
