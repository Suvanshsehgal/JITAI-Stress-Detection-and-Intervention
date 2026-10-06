import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stress_assessment.dart';

abstract class StressAssessmentRepository {
  Future<void> saveAssessment(StressAssessment assessment);
  Future<StressAssessment?> getLatestAssessment();
  Future<List<StressAssessment>> getAssessmentHistory();
  Future<void> clearHistory();
}

class LocalStressAssessmentRepository implements StressAssessmentRepository {
  final SharedPreferences _prefs;
  static const String _historyKey = 'stress_assessment_history';

  LocalStressAssessmentRepository(this._prefs);

  @override
  Future<void> saveAssessment(StressAssessment assessment) async {
    // Only persist valid, successful assessments. Never record failed or insufficientData as historical predictions.
    if (!assessment.isSuccessful) {
      return;
    }

    final history = await getAssessmentHistory();
    final updated = [assessment, ...history];
    // Keep reasonable history size (e.g. latest 100)
    final trimmed = updated.take(100).toList();
    final encoded = trimmed.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_historyKey, encoded);
  }

  @override
  Future<StressAssessment?> getLatestAssessment() async {
    final history = await getAssessmentHistory();
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<List<StressAssessment>> getAssessmentHistory() async {
    final raw = _prefs.getStringList(_historyKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      return raw
          .map((item) => StressAssessment.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
