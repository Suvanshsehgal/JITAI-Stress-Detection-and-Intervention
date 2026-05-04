import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final supabase = SupabaseConfig.client;

  // Create a new test session
  Future<String> createSession(String userId) async {
    final now = DateTime.now();
    
    final res = await supabase
        .from('test_sessions')
        .insert({
          'user_id': userId,
          'start_time': now.toIso8601String(),
          'test_start_hour': now.hour,
          'day_of_week': now.weekday % 7, // Convert Dart's 1(Mon)–7(Sun) to 0(Sun)–6(Sat)
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
    final totalScore = q1 + q2 + q3 + q4 + q5;
    final normalizedScore = totalScore / 25.0;

    await supabase.from('who5_responses').insert({
      'session_id': sessionId,
      'user_id': userId,
      'q1': q1,
      'q2': q2,
      'q3': q3,
      'q4': q4,
      'q5': q5,
      'total_score': totalScore,
      'normalized_score': normalizedScore,
    });
  }

  // Insert all cognitive metrics at once (NEW METHOD)
  Future<void> insertCognitiveMetrics({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> metrics,
  }) async {
    final data = {
      'session_id': sessionId,
      'user_id': userId,
      ...metrics, // Spread all collected metrics
    };

    await supabase.from('cognitive_metrics').insert(data);
  }

  // DEPRECATED: Use SessionManager.storeSpeedMetrics() + SessionManager.saveCognitiveMetrics() instead
  @Deprecated('Use SessionManager for consolidated metric saving')
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

  // DEPRECATED: Use SessionManager.storeStroopMetrics() + SessionManager.saveCognitiveMetrics() instead
  @Deprecated('Use SessionManager for consolidated metric saving')
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

  // DEPRECATED: Use SessionManager.storeMemoryMetrics() + SessionManager.saveCognitiveMetrics() instead
  @Deprecated('Use SessionManager for consolidated metric saving')
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

  // Get latest COMPLETED test session (end_time must not be null)
  Future<Map<String, dynamic>?> getLatestSession(String userId) async {
    try {
      final response = await supabase
          .from('test_sessions')
          .select()
          .eq('user_id', userId)
          .not('end_time', 'is', null) // ONLY completed tests
          .order('start_time', ascending: false) // order by actual test time
          .limit(1);

      debugPrint('✅ getLatestSession response: $response');

      if (response.isEmpty) {
        debugPrint('✅ No completed sessions found for user: $userId');
        return null;
      }

      debugPrint('✅ Latest session found: ${response.first}');
      return response.first;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching latest session: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // Get the latest stress score directly (most recent computed_at)
  Future<Map<String, dynamic>?> getLatestStressScore(String userId) async {
    try {
      final response = await supabase
          .from('stress_scores')
          .select('stress_score, stress_label_binary, session_id, computed_at')
          .eq('user_id', userId)
          .order('computed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching latest stress score: $e');
      return null;
    }
  }

  // Get total number of tests completed by user
  Future<int> getTotalTests(String userId) async {
    final res = await supabase
        .from('test_sessions')
        .select('id')
        .eq('user_id', userId);

    return (res as List).length;
  }

  // Get latest WHO-5 response for user
  Future<Map<String, dynamic>?> getLatestWHO5(String userId) async {
    final res = await supabase
        .from('who5_responses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return res;
  }

  // Get latest cognitive metrics for user
  Future<Map<String, dynamic>?> getLatestCognitiveMetrics(String userId) async {
    final res = await supabase
        .from('cognitive_metrics')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return res;
  }

  // Get latest physiological metrics for user
  Future<Map<String, dynamic>?> getLatestPhysiologicalMetrics(String userId) async {
    final res = await supabase
        .from('physiological_metrics')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return res;
  }

  // Get comprehensive user profile data
  Future<Map<String, dynamic>> getUserProfileData(String userId) async {
    try {
      final totalTests = await getTotalTests(userId);
      final latestSession = await getLatestSession(userId);
      final latestWHO5 = await getLatestWHO5(userId);
      final latestCognitive = await getLatestCognitiveMetrics(userId);
      final latestPhysiological = await getLatestPhysiologicalMetrics(userId);

      return {
        'totalTests': totalTests,
        'latestSession': latestSession,
        'latestWHO5': latestWHO5,
        'latestCognitive': latestCognitive,
        'latestPhysiological': latestPhysiological,
        'hasCompletedTest': latestSession != null,
      };
    } catch (e) {
      debugPrint('❌ Failed to get user profile data: $e');
      rethrow;
    }
  }

  // Insert sensor behavior metrics
  Future<void> insertSensorBehaviorMetrics({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> metrics,
  }) async {
    final data = {
      'session_id': sessionId,
      'user_id': userId,
      ...metrics,
    };

    await supabase.from('sensor_behavior_metrics').insert(data);
    debugPrint('✅ Sensor behavior metrics saved for phase: ${metrics['phase']}');
  }
}
