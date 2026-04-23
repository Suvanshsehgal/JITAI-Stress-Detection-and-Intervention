import '../config/supabase_config.dart';

class DatabaseService {
  final supabase = SupabaseConfig.client;

  // Create a new test session
  Future<String> createSession(String userId) async {
    final res = await supabase
        .from('test_sessions')
        .insert({
          'user_id': userId,
          'start_time': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return res['id'] as String;
  }

  // Update session end time
  Future<void> updateSessionEndTime(String sessionId) async {
    await supabase.from('test_sessions').update({
      'end_time': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  // Insert WHO-5 questionnaire responses
  Future<void> insertWHO5({
    required String sessionId,
    required String userId,
    required int q1,
    required int q2,
    required int q3,
    required int q4,
    required int q5,
  }) async {
    final total = q1 + q2 + q3 + q4 + q5;

    await supabase.from('who5_responses').insert({
      'session_id': sessionId,
      'user_id': userId,
      'q1': q1,
      'q2': q2,
      'q3': q3,
      'q4': q4,
      'q5': q5,
      'total_score': total,
      'normalized_score': total / 25.0, // 0-1 range as per your schema
    });
  }

  // Insert Speed Answer Test results into cognitive_metrics
  Future<void> insertSpeedAnswerResults({
    required String sessionId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    final accuracy = correctAnswers / totalQuestions;

    // Check if cognitive_metrics row exists for this session
    final existing = await supabase
        .from('cognitive_metrics')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (existing == null) {
      // Insert new row
      await supabase.from('cognitive_metrics').insert({
        'session_id': sessionId,
        'user_id': userId,
        'speed_accuracy': accuracy,
        'avg_response_time': averageResponseTime,
      });
    } else {
      // Update existing row
      await supabase.from('cognitive_metrics').update({
        'speed_accuracy': accuracy,
        'avg_response_time': averageResponseTime,
      }).eq('session_id', sessionId);
    }
  }

  // Insert Stroop Test results into cognitive_metrics
  Future<void> insertStroopResults({
    required String sessionId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    final accuracy = correctAnswers / totalQuestions;

    // Check if cognitive_metrics row exists for this session
    final existing = await supabase
        .from('cognitive_metrics')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (existing == null) {
      // Insert new row
      await supabase.from('cognitive_metrics').insert({
        'session_id': sessionId,
        'user_id': userId,
        'stroop_accuracy': accuracy,
        'stroop_avg_response_time': averageResponseTime,
      });
    } else {
      // Update existing row
      await supabase.from('cognitive_metrics').update({
        'stroop_accuracy': accuracy,
        'stroop_avg_response_time': averageResponseTime,
      }).eq('session_id', sessionId);
    }
  }

  // Insert Pattern Memory Test results into cognitive_metrics
  Future<void> insertPatternMemoryResults({
    required String sessionId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    final accuracy = correctAnswers / totalQuestions;

    // Check if cognitive_metrics row exists for this session
    final existing = await supabase
        .from('cognitive_metrics')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (existing == null) {
      // Insert new row
      await supabase.from('cognitive_metrics').insert({
        'session_id': sessionId,
        'user_id': userId,
        'memory_accuracy': accuracy,
        'memory_max_level': totalQuestions,
      });
    } else {
      // Update existing row
      await supabase.from('cognitive_metrics').update({
        'memory_accuracy': accuracy,
        'memory_max_level': totalQuestions,
      }).eq('session_id', sessionId);
    }
  }

  // Insert PPG Test results into physiological_metrics
  Future<void> insertPPGResults({
    required String sessionId,
    required String userId,
    required double heartRate,
    required double hrv,
    required double stressIndex,
  }) async {
    // Check if physiological_metrics row exists for this session
    final existing = await supabase
        .from('physiological_metrics')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (existing == null) {
      // Insert new row
      await supabase.from('physiological_metrics').insert({
        'session_id': sessionId,
        'user_id': userId,
        'heart_rate_avg': heartRate,
        'rmssd': hrv,
      });
    } else {
      // Update existing row (for post-test PPG)
      await supabase.from('physiological_metrics').update({
        'heart_rate_avg': heartRate,
        'rmssd': hrv,
      }).eq('session_id', sessionId);
    }
  }

  // Get user's test history
  Future<List<Map<String, dynamic>>> getUserTestHistory(String userId) async {
    final res = await supabase
        .from('test_sessions')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // Get latest test session
  Future<Map<String, dynamic>?> getLatestSession(String userId) async {
    final res = await supabase
        .from('test_sessions')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false)
        .limit(1)
        .maybeSingle();

    return res;
  }
}
