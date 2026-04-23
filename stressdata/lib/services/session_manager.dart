import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Global session manager for test flow
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  String? _currentSessionId;
  String? get sessionId => _currentSessionId;

  /// Start a new test session
  Future<bool> startSession() async {
    try {
      final userId = _authService.userId;
      
      if (userId == null) {
        debugPrint('❌ SessionManager: No user logged in');
        debugPrint('❌ Current user: ${_authService.currentUser}');
        return false;
      }

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
