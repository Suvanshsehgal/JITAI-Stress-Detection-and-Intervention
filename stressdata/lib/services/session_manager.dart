import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'auth_service.dart';
import '../models/sensor_data.dart';

/// Global session manager for test flow
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  String? _currentSessionId;
  String? get sessionId => _currentSessionId;

  // Store cognitive metrics from each test
  final Map<String, dynamic> _cognitiveMetrics = {};

  // Store sensor behavior metrics from each phase
  final List<SensorBehaviorMetrics> _sensorMetrics = [];

  /// Store Speed Test metrics
  void storeSpeedMetrics({
    required double accuracy,
    required double avgResponseTime,
    required int streakMax,
    int commissionErrors = 0,
    int omissionErrors = 0,
  }) {
    _cognitiveMetrics['speed_accuracy'] = accuracy;
    _cognitiveMetrics['avg_response_time'] = avgResponseTime;
    _cognitiveMetrics['streak_max'] = streakMax;
    _cognitiveMetrics['commission_errors'] = commissionErrors;
    _cognitiveMetrics['omission_errors'] = omissionErrors;
    debugPrint('✅ Speed Test metrics stored');
  }

  /// Store Stroop Test metrics
  void storeStroopMetrics({
    required double accuracy,
    required double avgResponseTime,
    double interferenceScore = 0.0,
  }) {
    _cognitiveMetrics['stroop_accuracy'] = accuracy;
    _cognitiveMetrics['stroop_avg_response_time'] = avgResponseTime;
    _cognitiveMetrics['stroop_interference_score'] = interferenceScore;
    debugPrint('✅ Stroop Test metrics stored');
  }

  /// Store Pattern Memory Test metrics
  void storeMemoryMetrics({
    required int maxLevel,
    required double accuracy,
  }) {
    _cognitiveMetrics['memory_max_level'] = maxLevel;
    _cognitiveMetrics['memory_accuracy'] = accuracy;
    debugPrint('✅ Memory Test metrics stored');
  }

  /// Store sensor behavior metrics
  void storeSensorMetrics(SensorBehaviorMetrics metrics) {
    _sensorMetrics.add(metrics);
    debugPrint('✅ Sensor metrics stored for phase: ${metrics.phase}');
  }

  /// Save all sensor behavior metrics to database
  Future<void> saveSensorMetrics() async {
    if (_currentSessionId == null) {
      debugPrint('❌ No active session to save sensor metrics');
      return;
    }

    if (_sensorMetrics.isEmpty) {
      debugPrint('⚠️ No sensor metrics to save');
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Save each phase's metrics
      for (final metrics in _sensorMetrics) {
        await _dbService.insertSensorBehaviorMetrics(
          sessionId: _currentSessionId!,
          userId: user.id,
          metrics: metrics.toJson(),
        );
      }

      debugPrint('✅ All sensor metrics saved to database (${_sensorMetrics.length} phases)');
      _sensorMetrics.clear(); // Clear after saving
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to save sensor metrics: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Save all cognitive metrics to database (call after all cognitive tests complete)
  Future<void> saveCognitiveMetrics() async {
    if (_currentSessionId == null) {
      debugPrint('❌ No active session to save cognitive metrics');
      return;
    }

    if (_cognitiveMetrics.isEmpty) {
      debugPrint('⚠️ No cognitive metrics to save');
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _dbService.insertCognitiveMetrics(
        sessionId: _currentSessionId!,
        userId: user.id,
        metrics: _cognitiveMetrics,
      );

      debugPrint('✅ Cognitive metrics saved to database');
      _cognitiveMetrics.clear(); // Clear after saving
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to save cognitive metrics: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Start a new test session
  Future<bool> startSession() async {
    try {
      // Get logged-in user
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        debugPrint('❌ SessionManager: No user logged in');
        return false;
      }

      final userId = user.id;
      debugPrint('✅ SessionManager: User ID found: $userId');
      debugPrint('✅ SessionManager: Creating session...');
      
      _currentSessionId = await _dbService.createSession(userId);
      
      debugPrint('✅ Session started successfully: $_currentSessionId');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to start session: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// End current test session
  Future<void> endSession() async {
    if (_currentSessionId == null) {
      debugPrint('⚠️ No active session to end');
      return;
    }

    try {
      // Save any remaining sensor metrics
      await saveSensorMetrics();
      
      await _dbService.updateSessionEndTime(_currentSessionId!);
      debugPrint('✅ Session ended: $_currentSessionId');
      _currentSessionId = null;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to end session: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Get current user ID
  String? get userId => _authService.userId;

  /// Check if session is active
  bool get hasActiveSession => _currentSessionId != null;
}
