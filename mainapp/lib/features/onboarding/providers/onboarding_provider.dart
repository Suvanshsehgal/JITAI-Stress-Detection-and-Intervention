import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../models/onboarding_state.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs) : super(const OnboardingState()) {
    _loadState();
  }

  void _loadState() {
    final buddyName = _prefs.getString('buddyName') ?? 'Pip';
    final toneStr = _prefs.getString('buddyTone');
    final tone = BuddyTone.values.firstWhere(
      (e) => e.name == toneStr,
      orElse: () => BuddyTone.gentle,
    );
    final goals = _prefs.getStringList('onboardingGoals')?.toSet() ?? {};
    final dataPrefs = _prefs.getStringList('onboardingDataPrefs')?.toSet() ?? {};
    final isCompleted = _prefs.getBool('onboardingCompleted') ?? false;

    state = OnboardingState(
      buddyName: buddyName,
      tone: tone,
      goals: goals,
      dataPrefs: dataPrefs,
      isCompleted: isCompleted,
    );
  }

  void updateBuddyName(String name) {
    state = state.copyWith(buddyName: name);
  }

  void updateTone(BuddyTone tone) {
    state = state.copyWith(tone: tone);
  }

  void toggleGoal(String goal) {
    final newGoals = Set<String>.from(state.goals);
    if (newGoals.contains(goal)) {
      newGoals.remove(goal);
    } else {
      newGoals.add(goal);
    }
    state = state.copyWith(goals: newGoals);
  }

  void toggleDataPref(String pref) {
    final newPrefs = Set<String>.from(state.dataPrefs);
    if (newPrefs.contains(pref)) {
      newPrefs.remove(pref);
    } else {
      newPrefs.add(pref);
    }
    state = state.copyWith(dataPrefs: newPrefs);
  }

  Future<void> completeOnboarding() async {
    final finalName = state.buddyName.trim().isEmpty ? 'Pip' : state.buddyName.trim();
    
    state = state.copyWith(buddyName: finalName, isCompleted: true);
    
    await _prefs.setString('buddyName', state.buddyName);
    await _prefs.setString('buddyTone', state.tone.name);
    await _prefs.setStringList('onboardingGoals', state.goals.toList());
    await _prefs.setStringList('onboardingDataPrefs', state.dataPrefs.toList());
    await _prefs.setBool('onboardingCompleted', true);
  }
}
