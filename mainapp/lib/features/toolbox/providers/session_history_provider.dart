import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../models/intervention_session.dart';

final sessionHistoryProvider = StateNotifierProvider<SessionHistoryNotifier, List<InterventionSession>>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return SessionHistoryNotifier(prefs);
});

class SessionHistoryNotifier extends StateNotifier<List<InterventionSession>> {
  final SharedPreferences _prefs;
  static const _key = 'intervention_history';

  SessionHistoryNotifier(this._prefs) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    final historyString = _prefs.getStringList(_key);
    if (historyString != null) {
      try {
        final history = historyString
            .map((str) => InterventionSession.fromJson(jsonDecode(str)))
            .toList();
        state = history;
      } catch (_) {
        state = [];
      }
    }
  }

  void saveSession(InterventionSession session) {
    // Only completed sessions should be added to history per requirements,
    // but the session itself tracks status. We will enforce that only completed 
    // ones show up in history view, but we can save it anyway or just save completed.
    if (session.status != SessionStatus.completed) return;

    final newState = [session, ...state];
    state = newState;
    _persistHistory();
  }

  void _persistHistory() {
    final historyString = state.map((s) => jsonEncode(s.toJson())).toList();
    _prefs.setStringList(_key, historyString);
  }
}
