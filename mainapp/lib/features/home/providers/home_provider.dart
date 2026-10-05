import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  void setMood(String mood) {
    if (state.selectedMood == mood) {
      state = state.copyWith(clearMood: true);
    } else {
      state = state.copyWith(selectedMood: mood);
    }
  }

  // Demonstration method to test UI missing data
  void clearHealthData() {
    state = state.copyWith(
      healthSnapshot: const HealthSnapshot(heartRate: null, hrv: null, sleep: null),
    );
  }

  // Demonstration method to reset UI data
  void resetDemoData() {
    state = const HomeState();
  }
}
