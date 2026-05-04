/// Result of sensor data capture with computed features
class SensorReadingResult {
  final int sampleCount;
  final double captureDurationSec;
  final String dataQuality; // 'good' | 'partial' | 'poor'
  final double movementIntensity; // mean magnitude
  final double movementVariance;
  final int accelPeakCount;
  final double zeroCrossingRate;
  final String activityLevel; // 'low' | 'medium' | 'high'
  final double? rotationVariance; // nullable
  final bool gyroAvailable;
  final double restlessnessScore;

  SensorReadingResult({
    required this.sampleCount,
    required this.captureDurationSec,
    required this.dataQuality,
    required this.movementIntensity,
    required this.movementVariance,
    required this.accelPeakCount,
    required this.zeroCrossingRate,
    required this.activityLevel,
    this.rotationVariance,
    required this.gyroAvailable,
    required this.restlessnessScore,
  });

  @override
  String toString() {
    return 'SensorReadingResult('
        'samples: $sampleCount, '
        'duration: ${captureDurationSec.toStringAsFixed(1)}s, '
        'quality: $dataQuality, '
        'intensity: ${movementIntensity.toStringAsFixed(2)}, '
        'activity: $activityLevel, '
        'restlessness: ${restlessnessScore.toStringAsFixed(2)}'
        ')';
  }
}
