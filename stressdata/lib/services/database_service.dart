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
      'normalized_score': (total / 25.0) * 100,
    });
  }

  // Insert Speed Answer Test results
  Future<void> insertSpeedAnswerResults({
    required String sessionId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    await supabase.from('speed_answer_results').insert({
      'session_id': sessionId,
      'user_id': userId,
      'score': score,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'average_response_time': averageResponseTime,
    });
  }

  // Insert Stroop Test results
  Future<void> insertStroopResults({
    required String sessionId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    await supabase.from('stroop_results').insert({
      'session_id': sessionId,
      'user_id': userId,
      'score': score,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'average_response_time': averageResponseTime,
    });
  }

  // Insert Pattern Memory Test results
  Future<void> insertPatternMemoryResults({
    required String sessionId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    await supabase.from('pattern_memory_results').insert({
      'session_id': sessionId,
      'user_id': userId,
      'score': score,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'average_response_time': averageResponseTime,
    });
  }

  // Insert PPG Test results
  Future<void> insertPPGResults({
    required String sessionId,
    required String userId,
    required double heartRate,
    required double hrv,
    required double stressIndex,
  }) async {
    await supabase.from('ppg_results').insert({
      'session_id': sessionId,
      'user_id': userId,
      'heart_rate': heartRate,
      'hrv': hrv,
      'stress_index': stressIndex,
    });
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