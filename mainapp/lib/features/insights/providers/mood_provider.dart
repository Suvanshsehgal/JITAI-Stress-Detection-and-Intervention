import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../models/mood_entry.dart';

final moodProvider = StateNotifierProvider<MoodNotifier, List<MoodEntry>>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return MoodNotifier(prefs);
});

class MoodNotifier extends StateNotifier<List<MoodEntry>> {
  final SharedPreferences _prefs;
  static const _key = 'mood_entries';

  MoodNotifier(this._prefs) : super([]) {
    _loadMoods();
  }

  void _loadMoods() {
    final strings = _prefs.getStringList(_key);
    if (strings != null) {
      try {
        final moods = strings
            .map((str) => MoodEntry.fromJson(jsonDecode(str)))
            .toList();
        // Sort newest first
        moods.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        state = moods;
      } catch (_) {
        state = [];
      }
    }
  }

  void addMood(MoodEntry entry) {
    final newState = [entry, ...state];
    newState.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = newState;
    _persistMoods();
  }

  void _persistMoods() {
    final strings = state.map((m) => jsonEncode(m.toJson())).toList();
    _prefs.setStringList(_key, strings);
  }
}
