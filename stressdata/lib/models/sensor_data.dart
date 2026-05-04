/// Model for sensor behavior metrics
class SensorBehaviorMetrics {
  final String phase;
  final double movementIntensity;
  final double movementVariance;
  final String activityLevel;
  final double? rotationVariance;
  final int hesitationCount;
  final int rapidGuessCount;
  final double captureDurationSec;
  final DateTime timestamp;

  SensorBehaviorMetrics({
    required this.phase,
    required this.movementIntensity,
    required this.movementVariance,
    required this.activityLevel,
    this.rotationVariance,
    required this.hesitationCount,
    required this.rapidGuessCount,
    required this.captureDurationSec,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'phase': phase,
      'movement_intensity': movementIntensity,
      'movement_variance': movementVariance,
      'activity_level': activityLevel,
      'rotation_variance': rotationVariance,
      'hesitation_count': hesitationCount,
      'rapid_guess_count': rapidGuessCount,
      'capture_duration_sec': captureDurationSec,
      'captured_at': timestamp.toIso8601String(),
    };
  }
}

/// Enum for test phases
enum TestPhase {
  preTest('pre_test'),
  duringStroop('during_stroop'),
  duringSpeed('during_speed'),
  duringMemory('during_memory'),
  betweenTests('between_tests'),
  postTest('post_test'),
  recovery('recovery');

  final String value;
  const TestPhase(this.value);
}

/// Activity level classification
enum ActivityLevel {
  low,
  medium,
  high;

  static ActivityLevel fromIntensity(double intensity) {
    if (intensity < 0.5) return ActivityLevel.low;
    if (intensity < 1.5) return ActivityLevel.medium;
    return ActivityLevel.high;
  }
}
