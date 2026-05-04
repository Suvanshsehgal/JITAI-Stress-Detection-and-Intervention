import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';

/// Service for capturing and processing sensor data
class SensorService {
  // Sensor stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Data buffers
  final List<double> _accelerometerMagnitudes = [];
  final List<double> _gyroscopeMagnitudes = [];
  final List<DateTime> _timestamps = [];

  // Behavioral tracking
  int _hesitationCount = 0;
  int _rapidGuessCount = 0;
  DateTime? _lastInteractionTime;

  // Capture state
  bool _isCapturing = false;
  DateTime? _captureStartTime;
  String _currentPhase = '';

  // Configuration
  static const Duration _samplingInterval = Duration(milliseconds: 100);
  static const double _hesitationThresholdSec = 3.0;
  static const double _rapidGuessThresholdSec = 0.5;

  bool get isCapturing => _isCapturing;

  /// Start capturing sensor data for a specific phase
  Future<void> startCapture(TestPhase phase) async {
    if (_isCapturing) {
      debugPrint('⚠️ Sensor capture already in progress');
      return;
    }

    _isCapturing = true;
    _currentPhase = phase.value;
    _captureStartTime = DateTime.now();
    _clearBuffers();

    debugPrint('✅ Starting sensor capture for phase: ${phase.value}');

    // Start accelerometer with throttling
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: _samplingInterval,
    ).listen(
      _onAccelerometerEvent,
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
      },
    );

    // Start gyroscope (optional) with throttling
    try {
      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: _samplingInterval,
      ).listen(
        _onGyroscopeEvent,
        onError: (error) {
          debugPrint('⚠️ Gyroscope error (optional): $error');
        },
      );
    } catch (e) {
      debugPrint('⚠️ Gyroscope not available: $e');
    }
  }

  /// Stop capturing and compute features
  Future<SensorBehaviorMetrics?> stopCapture() async {
    if (!_isCapturing) {
      debugPrint('⚠️ No active sensor capture to stop');
      return null;
    }

    debugPrint('🛑 Stopping sensor capture for phase: $_currentPhase');

    // Stop subscriptions immediately
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;

    _isCapturing = false;

    // Compute features
    if (_accelerometerMagnitudes.isEmpty) {
      debugPrint('⚠️ No sensor data captured');
      return null;
    }

    final metrics = _computeFeatures();
    debugPrint('✅ Computed sensor metrics for ${_currentPhase}:');
    debugPrint('   Movement intensity: ${metrics.movementIntensity.toStringAsFixed(3)}');
    debugPrint('   Activity level: ${metrics.activityLevel}');
    debugPrint('   Hesitations: ${metrics.hesitationCount}');
    debugPrint('   Rapid guesses: ${metrics.rapidGuessCount}');

    return metrics;
  }

  /// Handle accelerometer events
  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isCapturing) return;

    // Calculate magnitude: sqrt(x² + y² + z²)
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    _accelerometerMagnitudes.add(magnitude);
    _timestamps.add(DateTime.now());

    // Keep buffer size manageable (max 10 minutes at 10Hz = 6000 samples)
    if (_accelerometerMagnitudes.length > 6000) {
      _accelerometerMagnitudes.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  /// Handle gyroscope events
  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isCapturing) return;

    // Calculate rotation magnitude
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    _gyroscopeMagnitudes.add(magnitude);

    // Keep buffer size manageable
    if (_gyroscopeMagnitudes.length > 6000) {
      _gyroscopeMagnitudes.removeAt(0);
    }
  }

  /// Track user interaction (for hesitation/rapid guess detection)
  void trackInteraction() {
    final now = DateTime.now();

    if (_lastInteractionTime != null) {
      final timeSinceLastInteraction =
          now.difference(_lastInteractionTime!).inMilliseconds / 1000.0;

      // Detect hesitation (long pause)
      if (timeSinceLastInteraction > _hesitationThresholdSec) {
        _hesitationCount++;
      }

      // Detect rapid guess (very fast response)
      if (timeSinceLastInteraction < _rapidGuessThresholdSec) {
        _rapidGuessCount++;
      }
    }

    _lastInteractionTime = now;
  }

  /// Compute aggregated features from sensor data
  SensorBehaviorMetrics _computeFeatures() {
    final captureDuration = DateTime.now().difference(_captureStartTime!).inSeconds.toDouble();

    // Compute movement intensity (mean magnitude)
    final movementIntensity = _accelerometerMagnitudes.isEmpty
        ? 0.0
        : _accelerometerMagnitudes.reduce((a, b) => a + b) / _accelerometerMagnitudes.length;

    // Compute movement variance
    final movementVariance = _computeVariance(_accelerometerMagnitudes, movementIntensity);

    // Classify activity level
    final activityLevel = ActivityLevel.fromIntensity(movementIntensity).name;

    // Compute rotation variance (if available)
    double? rotationVariance;
    if (_gyroscopeMagnitudes.isNotEmpty) {
      final gyroMean = _gyroscopeMagnitudes.reduce((a, b) => a + b) / _gyroscopeMagnitudes.length;
      rotationVariance = _computeVariance(_gyroscopeMagnitudes, gyroMean);
    }

    return SensorBehaviorMetrics(
      phase: _currentPhase,
      movementIntensity: movementIntensity,
      movementVariance: movementVariance,
      activityLevel: activityLevel,
      rotationVariance: rotationVariance,
      hesitationCount: _hesitationCount,
      rapidGuessCount: _rapidGuessCount,
      captureDurationSec: captureDuration,
      timestamp: DateTime.now(),
    );
  }

  /// Compute variance of a list of values
  double _computeVariance(List<double> values, double mean) {
    if (values.length < 2) return 0.0;

    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;

    return variance;
  }

  /// Clear all buffers
  void _clearBuffers() {
    _accelerometerMagnitudes.clear();
    _gyroscopeMagnitudes.clear();
    _timestamps.clear();
    _hesitationCount = 0;
    _rapidGuessCount = 0;
    _lastInteractionTime = null;
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    _clearBuffers();
    _isCapturing = false;
    debugPrint('🧹 SensorService disposed');
  }
}
