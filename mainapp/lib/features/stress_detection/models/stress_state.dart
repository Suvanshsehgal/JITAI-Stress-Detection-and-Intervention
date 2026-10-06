enum StressState {
  baseline,
  elevated,
  high,
  unknown,
}

extension StressStateExtension on StressState {
  String get label {
    switch (this) {
      case StressState.baseline:
        return 'Steady';
      case StressState.elevated:
        return 'Mildly Elevated';
      case StressState.high:
        return 'High Activation';
      case StressState.unknown:
        return 'Observing Patterns';
    }
  }

  String get description {
    switch (this) {
      case StressState.baseline:
        return 'Your signals indicate a steady, balanced state.';
      case StressState.elevated:
        return 'Slight activation detected in recent contextual patterns.';
      case StressState.high:
        return 'Elevated activation detected in recent contextual patterns.';
      case StressState.unknown:
        return 'Not enough contextual observations to estimate activation state.';
    }
  }
}
