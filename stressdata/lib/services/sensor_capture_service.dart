import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../config/supabase_config.dart';
import '../models/sensor_reading_result.dart';

/// Singleton service for capturing and processing sensor data
class SensorCaptureService {
  static final SensorCaptureService _instance = SensorCaptureService._internal();
  factory SensorCaptureService() => _instance;
  SensorCaptureService._internal();

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Raw data storage
  final List<AccelerometerEvent> _accelEvents = [];
  final List<GyroscopeEvent> _gyroEvents = [];

  // Capture state
  DateTime? _captureStartTime;
  String? _currentPhase;
  bool _gyroAvailable = false;
  bool _isCapturing = false;

  /// METHOD 1: Start capturing sensor data
  void startCapture(String phase) {
    if (_isCapturing) {
      debugPrint('⚠️ Sensor capture already in progress');
      return;
    }

    _isCapturing = true;
    _currentPhase = phase;
    _captureStartTime = DateTime.now();
    _accelEvents.clear();
    _gyroEvents.clear();
    _gyroAvailable = false;

    debugPrint('📊 Starting sensor capture for phase: $phase');

    // Subscribe to accelerometer
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (event) {
        if (_isCapturing) {
          _accelEvents.add(event);
        }
      },
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
      },
    );

    // Try to subscribe to gyroscope
    try {
      _gyroSubscription = gyroscopeEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (_isCapturing) {
            _gyroEvents.add(event);
            _gyroAvailable = true;
          }
        },
        onError: (error) {
          debugPrint('⚠️ Gyroscope error (optional): $error');
          _gyroAvailable = false;
        },
      );
    } catch (e) {
      debugPrint('⚠️ Gyroscope not available: $e');
      _gyroAvailable = false;
    }
  }

  /// METHOD 2: Stop capture and compute features
  Future<SensorReadingResult> stopCapture() async {
    if (!_isCapturing) {
      throw Exception('No active sensor capture to stop');
    }

    debugPrint('🛑 Stopping sensor capture for phase: $_currentPhase');

    // Cancel subscriptions
    await _accelSubscription?.cancel();
    await _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
    _isCapturing = false;

    // Compute duration
    final endTime = DateTime.now();
    final captureDurationSec = endTime.difference(_captureStartTime!).inMilliseconds / 1000.0;

    // Compute accelerometer features
    final magnitudes = _accelEvents.map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z)).toList();

    if (magnitudes.isEmpty) {
      throw Exception('No accelerometer data captured');
    }

    final sampleCount = magnitudes.length;
    final movementIntensity = _mean(magnitudes);
    final movementVariance = _variance(magnitudes, movementIntensity);
    final stdDev = sqrt(movementVariance);

    // Compute peak count
    final threshold = movementIntensity + (1.5 * stdDev);
    final accelPeakCount = magnitudes.where((m) => m > threshold).length;

    // Compute zero crossing rate
    int crossings = 0;
    for (int i = 1; i < magnitudes.length; i++) {
      if ((magnitudes[i - 1] < movementIntensity && magnitudes[i] >= movementIntensity) ||
          (magnitudes[i - 1] >= movementIntensity && magnitudes[i] < movementIntensity)) {
        crossings++;
      }
    }
    final zeroCrossingRate = crossings / captureDurationSec;

    // Classify activity level
    String activityLevel;
    if (movementIntensity < 10.5) {
      activityLevel = 'low';
    } else if (movementIntensity <= 12.0) {
      activityLevel = 'medium';
    } else {
      activityLevel = 'high';
    }

    // Compute gyroscope features (if available)
    double? rotationVariance;
    if (_gyroAvailable && _gyroEvents.isNotEmpty) {
      final gyroMagnitudes = _gyroEvents.map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z)).toList();
      final gyroMean = _mean(gyroMagnitudes);
      rotationVariance = _variance(gyroMagnitudes, gyroMean);
    }

    // Compute restlessness score
    final restlessnessScore = _gyroAvailable && rotationVariance != null
        ? (movementVariance * 0.6) + (rotationVariance * 0.4)
        : movementVariance;

    // Compute data quality
    final expectedSamples = captureDurationSec * 10; // 10 Hz expected
    final String dataQuality;
    if (sampleCount >= expectedSamples * 0.9) {
      dataQuality = 'good';
    } else if (sampleCount >= expectedSamples * 0.5) {
      dataQuality = 'partial';
    } else {
      dataQuality = 'poor';
    }

    // Clear raw data
    _accelEvents.clear();
    _gyroEvents.clear();

    final result = SensorReadingResult(
      sampleCount: sampleCount,
      captureDurationSec: captureDurationSec,
      dataQuality: dataQuality,
      movementIntensity: movementIntensity,
      movementVariance: movementVariance,
      accelPeakCount: accelPeakCount,
      zeroCrossingRate: zeroCrossingRate,
      activityLevel: activityLevel,
      rotationVariance: rotationVariance,
      gyroAvailable: _gyroAvailable,
      restlessnessScore: restlessnessScore,
    );

    debugPrint('✅ Sensor capture complete: $result');
    return result;
  }

  /// METHOD 3: Compute baseline deviation
  Future<double?> computeBaselineDeviation(double currentIntensity) async {
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('⚠️ No user logged in for baseline computation');
        return null;
      }

      final response = await supabase
          .from('user_baselines')
          .select('baseline_movement_mean')
          .eq('user_id', userId)
          .order('computed_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('ℹ️ No baseline found for user');
        return null;
      }

      final baseline = response.first['baseline_movement_mean'] as double;
      final deviation = ((currentIntensity - baseline) / baseline) * 100;

      debugPrint('📊 Baseline deviation: ${deviation.toStringAsFixed(2)}%');
      return deviation;
    } catch (e) {
      debugPrint('❌ Error computing baseline deviation: $e');
      return null;
    }
  }

  /// METHOD 4: Save to database
  Future<void> saveToDatabase({
    required SensorReadingResult result,
    required String sessionId,
    required String phase,
    int? selfReportedStress,
    double? ppgBpm,
    double? hrvEstimate,
    int? pssScore,
    int? hesitationCount,
    int? rapidGuessCount,
    bool isBaselineSession = false,
  }) async {
    try {
      final supabase = SupabaseConfig.client;

      // Must have authenticated user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Sensor save aborted: no authenticated user');
        return;
      }

      // Compute stress label
      int? stressLabel;
      if (selfReportedStress != null) {
        stressLabel = selfReportedStress >= 3 ? 1 : 0;
      } else if (pssScore != null) {
        stressLabel = pssScore >= 14 ? 1 : 0;
      }

      // Compute baseline deviation (non-blocking — null is fine)
      final baselineDeviation = await computeBaselineDeviation(result.movementIntensity);

      final data = {
        'session_id': sessionId,
        'user_id': userId,
        'phase': phase,
        'sample_count': result.sampleCount,
        'capture_duration_sec': result.captureDurationSec,
        'data_quality': result.dataQuality,
        'movement_intensity': result.movementIntensity,
        'movement_variance': result.movementVariance,
        'accel_peak_count': result.accelPeakCount,
        'zero_crossing_rate': result.zeroCrossingRate,
        'activity_level': result.activityLevel,
        'baseline_deviation': baselineDeviation,
        'is_baseline_session': isBaselineSession,
        'rotation_variance': result.rotationVariance,
        'gyro_available': result.gyroAvailable,
        'restlessness_score': result.restlessnessScore,
        'hesitation_count': hesitationCount ?? 0,
        'rapid_guess_count': rapidGuessCount ?? 0,
        'ppg_bpm': ppgBpm,
        'hrv_estimate': hrvEstimate,
        'self_reported_stress': selfReportedStress,
        'pss_score': pssScore,
        'stress_label': stressLabel,
      };

      debugPrint('📤 Inserting sensor data: phase=$phase, session=$sessionId, user=$userId');
      await supabase.from('sensor_behavior_metrics').insert(data);
      debugPrint('✅ Sensor data saved: phase=$phase');
    } catch (e, stackTrace) {
      debugPrint('❌ Sensor save FAILED for phase=$phase: $e');
      debugPrint('❌ Stack: $stackTrace');
    }
  }

  /// METHOD 5: Compute and save baseline
  Future<void> computeAndSaveBaseline(List<String> sessionIds) async {
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('⚠️ No user logged in for baseline computation');
        return;
      }

      debugPrint('📊 Computing baseline from ${sessionIds.length} sessions');

      // Query baseline sessions
      final response = await supabase
          .from('sensor_behavior_metrics')
          .select()
          .inFilter('session_id', sessionIds)
          .eq('phase', 'pre_test')
          .eq('is_baseline_session', true);

      if (response.isEmpty) {
        debugPrint('⚠️ No baseline sessions found');
        return;
      }

      final sessions = response as List;
      final sessionsUsed = sessions.length;

      // Compute averages
      double sumMovementIntensity = 0;
      double sumMovementVariance = 0;
      double sumPeakCount = 0;
      double sumPpgBpm = 0;
      double sumHrv = 0;
      int ppgCount = 0;
      int hrvCount = 0;

      for (final session in sessions) {
        sumMovementIntensity += session['movement_intensity'] as double;
        sumMovementVariance += session['movement_variance'] as double;
        sumPeakCount += (session['accel_peak_count'] as int).toDouble();

        if (session['ppg_bpm'] != null) {
          sumPpgBpm += session['ppg_bpm'] as double;
          ppgCount++;
        }

        if (session['hrv_estimate'] != null) {
          sumHrv += session['hrv_estimate'] as double;
          hrvCount++;
        }
      }

      final baselineData = {
        'baseline_movement_mean': sumMovementIntensity / sessionsUsed,
        'baseline_movement_variance': sumMovementVariance / sessionsUsed,
        'baseline_peak_count': sumPeakCount / sessionsUsed,
        'baseline_ppg_bpm': ppgCount > 0 ? sumPpgBpm / ppgCount : null,
        'baseline_hrv': hrvCount > 0 ? sumHrv / hrvCount : null,
        'sessions_used': sessionsUsed,
      };

      // Upsert baseline (DO NOT include user_id - auto-set by auth.uid())
      await supabase.from('user_baselines').upsert(
            baselineData,
            onConflict: 'user_id',
          );

      debugPrint('✅ Baseline computed and saved: $baselineData');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to compute baseline: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Helper: Compute mean
  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Helper: Compute variance
  double _variance(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await _accelSubscription?.cancel();
    await _gyroSubscription?.cancel();
    _accelEvents.clear();
    _gyroEvents.clear();
    _isCapturing = false;
    debugPrint('🧹 SensorCaptureService disposed');
  }
}
