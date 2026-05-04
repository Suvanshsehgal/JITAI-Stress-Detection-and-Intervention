import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Result returned after computing stress score
class StressScoreResult {
  final double stressScore;
  final int stressLabelBinary;
  final double labelConfidence;

  // Component scores
  final double who5Stress;
  final double hrvStress;
  final double hrStress;
  final double cognitiveStress;
  final double behaviorStress;
  final double selfReportStress;
  final double baselineStress;

  StressScoreResult({
    required this.stressScore,
    required this.stressLabelBinary,
    required this.labelConfidence,
    required this.who5Stress,
    required this.hrvStress,
    required this.hrStress,
    required this.cognitiveStress,
    required this.behaviorStress,
    required this.selfReportStress,
    required this.baselineStress,
  });

  @override
  String toString() =>
      'StressScore(score: ${stressScore.toStringAsFixed(3)}, '
      'label: $stressLabelBinary, confidence: ${labelConfidence.toStringAsFixed(3)})';
}

class StressScoreService {
  static final StressScoreService _instance = StressScoreService._internal();
  factory StressScoreService() => _instance;
  StressScoreService._internal();

  final _supabase = SupabaseConfig.client;

  // ─── Clamp helper ────────────────────────────────────────────────────────
  double _clamp(double value, [double min = 0.0, double max = 1.0]) {
    return value.clamp(min, max);
  }

  // ─── Safe cast helpers ────────────────────────────────────────────────────
  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return fallback;
  }

  // ─── STEP 1: Fetch all data ───────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchSessionData(String sessionId) async {
    final results = await Future.wait([
      _supabase
          .from('who5_responses')
          .select('normalized_score')
          .eq('session_id', sessionId)
          .maybeSingle(),
      _supabase
          .from('physiological_metrics')
          .select('heart_rate_avg, rmssd, ppg_signal_quality')
          .eq('session_id', sessionId)
          .maybeSingle(),
      _supabase
          .from('cognitive_metrics')
          .select(
              'stroop_interference_score, stroop_avg_response_time, stroop_accuracy, commission_errors, omission_errors')
          .eq('session_id', sessionId)
          .maybeSingle(),
      _supabase
          .from('sensor_behavior_metrics')
          .select('restlessness_score, baseline_deviation, self_reported_stress, data_quality')
          .eq('session_id', sessionId)
          .eq('phase', 'pre_test')
          .maybeSingle(),
      _supabase
          .from('user_baselines')
          .select('baseline_ppg_bpm, baseline_hrv')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('computed_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    return {
      'who5': results[0],
      'physio': results[1],
      'cognitive': results[2],
      'sensor': results[3],
      'baseline': results[4],
    };
  }

  // ─── STEP 2–3: Normalize all components ──────────────────────────────────

  double _computeWho5Stress(Map<String, dynamic>? who5) {
    if (who5 == null) return 0.5;
    final normalized = _toDouble(who5['normalized_score'], -1);
    if (normalized < 0) return 0.5;
    return _clamp(1.0 - normalized);
  }

  double _computeSelfReportStress(Map<String, dynamic>? sensor) {
    if (sensor == null) return 0.5;
    final raw = _toDouble(sensor['self_reported_stress'], -1);
    if (raw < 1) return 0.5;
    return _clamp((raw - 1) / 4.0);
  }

  double _computeHrStress(Map<String, dynamic>? physio) {
    if (physio == null) return 0.5;
    final hr = _toDouble(physio['heart_rate_avg'], -1);
    if (hr < 0) return 0.5;
    return _clamp((hr - 60) / 40.0);
  }

  double _computeHrvStress(Map<String, dynamic>? physio) {
    if (physio == null) return 0.5;
    final rmssd = _toDouble(physio['rmssd'], -1);
    if (rmssd < 0) return 0.5;
    return _clamp(1.0 - _clamp(rmssd / 100.0));
  }

  double _computeCognitiveStress(Map<String, dynamic>? cognitive) {
    if (cognitive == null) return 0.5;

    // Normalize each component to 0–1
    final interference = _clamp(_toDouble(cognitive['stroop_interference_score'], 0.5));
    final avgRt = _clamp(_toDouble(cognitive['stroop_avg_response_time'], 1500) / 3000.0);
    final accuracy = _clamp(_toDouble(cognitive['stroop_accuracy'], 0.5));
    final errors = _clamp(
      (_toDouble(cognitive['commission_errors'], 0) +
              _toDouble(cognitive['omission_errors'], 0)) /
          20.0,
    );

    return _clamp(
      0.4 * interference +
          0.3 * avgRt +
          0.2 * (1.0 - accuracy) +
          0.1 * errors,
    );
  }

  double _computeBehaviorStress(Map<String, dynamic>? sensor) {
    if (sensor == null) return 0.5;

    final restlessness = _toDouble(sensor['restlessness_score'], -1);
    final baselineDev = _toDouble(sensor['baseline_deviation'], -1);

    // Normalize restlessness (typical range 0–5)
    final normRestlessness = restlessness >= 0 ? _clamp(restlessness / 5.0) : 0.5;

    // Normalize baseline deviation (percentage, typical range -100 to +100)
    final normBaselineDev = baselineDev >= -100
        ? _clamp((baselineDev + 100) / 200.0)
        : 0.5;

    return _clamp(0.6 * normRestlessness + 0.4 * normBaselineDev);
  }

  double _computeBaselineStress(
    Map<String, dynamic>? physio,
    Map<String, dynamic>? baseline,
  ) {
    if (physio == null || baseline == null) return 0.5;

    final hr = _toDouble(physio['heart_rate_avg'], -1);
    final rmssd = _toDouble(physio['rmssd'], -1);
    final baselineHr = _toDouble(baseline['baseline_ppg_bpm'], -1);
    final baselineHrv = _toDouble(baseline['baseline_hrv'], -1);

    if (hr < 0 || rmssd < 0 || baselineHr < 0 || baselineHrv < 0) return 0.5;

    final hrDiff = hr - baselineHr;
    final hrvDiff = baselineHrv - rmssd;
    final combined = hrDiff + hrvDiff;

    // Normalize: typical combined range -100 to +100
    return _clamp((combined + 100) / 200.0);
  }

  // ─── STEP 6: Confidence score ─────────────────────────────────────────────
  double _computeConfidence(
    Map<String, dynamic>? physio,
    Map<String, dynamic>? who5,
    Map<String, dynamic>? cognitive,
  ) {
    final ppgQuality = _toDouble(physio?['ppg_signal_quality'], 0.5);
    final who5Exists = who5 != null ? 1.0 : 0.5;
    final cognitiveExists = cognitive != null ? 1.0 : 0.5;

    return _clamp((ppgQuality + who5Exists + cognitiveExists) / 3.0);
  }

  // ─── STEP 7: Insert into database ────────────────────────────────────────
  Future<void> _saveToDatabase({
    required String sessionId,
    required StressScoreResult result,
  }) async {
    final data = {
      'session_id': sessionId,
      'stress_score': result.stressScore,
      'stress_label_binary': result.stressLabelBinary,
      'label_confidence': result.labelConfidence,
      'label_source': 'composite',
      'who5_stress': result.who5Stress,
      'hrv_stress': result.hrvStress,
      'hr_stress': result.hrStress,
      'cognitive_stress': result.cognitiveStress,
      'behavior_stress': result.behaviorStress,
      'self_report_stress': result.selfReportStress,
      'baseline_stress': result.baselineStress,
    };

    await _supabase
        .from('stress_scores')
        .upsert(data, onConflict: 'session_id');

    debugPrint('✅ Stress score saved: $result');
  }

  // ─── PUBLIC: Compute and save ─────────────────────────────────────────────
  /// Fetches all session data, computes stress score on-device, saves to DB.
  /// Returns the result or null if computation fails.
  Future<StressScoreResult?> computeAndSave(String sessionId) async {
    try {
      debugPrint('📊 Computing stress score for session: $sessionId');

      // STEP 1: Fetch
      final data = await _fetchSessionData(sessionId);

      final who5 = data['who5'] as Map<String, dynamic>?;
      final physio = data['physio'] as Map<String, dynamic>?;
      final cognitive = data['cognitive'] as Map<String, dynamic>?;
      final sensor = data['sensor'] as Map<String, dynamic>?;
      final baseline = data['baseline'] as Map<String, dynamic>?;

      // STEP 2–3: Normalize components (with fallbacks)
      final who5Stress = _computeWho5Stress(who5);
      final selfReportStress = _computeSelfReportStress(sensor);
      final hrStress = _computeHrStress(physio);
      final hrvStress = _computeHrvStress(physio);
      final cognitiveStress = _computeCognitiveStress(cognitive);
      final behaviorStress = _computeBehaviorStress(sensor);
      final baselineStress = _computeBaselineStress(physio, baseline);

      // STEP 4: Weighted final score
      final rawScore = 0.30 * who5Stress +
          0.20 * hrvStress +
          0.10 * hrStress +
          0.15 * cognitiveStress +
          0.10 * behaviorStress +
          0.10 * selfReportStress +
          0.05 * baselineStress;

      final stressScore = _clamp(rawScore);

      // STEP 5: Binary label
      final stressLabelBinary = stressScore >= 0.6 ? 1 : 0;

      // STEP 6: Confidence
      final labelConfidence = _computeConfidence(physio, who5, cognitive);

      final result = StressScoreResult(
        stressScore: stressScore,
        stressLabelBinary: stressLabelBinary,
        labelConfidence: labelConfidence,
        who5Stress: who5Stress,
        hrvStress: hrvStress,
        hrStress: hrStress,
        cognitiveStress: cognitiveStress,
        behaviorStress: behaviorStress,
        selfReportStress: selfReportStress,
        baselineStress: baselineStress,
      );

      // STEP 7: Save
      await _saveToDatabase(sessionId: sessionId, result: result);

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Stress score computation failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }
}
