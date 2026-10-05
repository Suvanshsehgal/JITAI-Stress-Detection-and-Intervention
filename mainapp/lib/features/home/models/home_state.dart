

class HealthSnapshot {
  final int? heartRate;
  final int? hrv;
  final String? sleep; // e.g. "7h 20m"

  const HealthSnapshot({
    this.heartRate,
    this.hrv,
    this.sleep,
  });
}

class SuggestedAction {
  final String title;
  final String description;
  final String duration;

  const SuggestedAction({
    required this.title,
    required this.description,
    required this.duration,
  });
}

class HomeState {
  final String currentWellbeing;
  final HealthSnapshot healthSnapshot;
  final SuggestedAction? suggestedAction;
  final List<String> whyNowReasons;
  final String? selectedMood;
  final double baselineProgress; // 0.0 to 1.0

  const HomeState({
    this.currentWellbeing = "You're feeling steady",
    this.healthSnapshot = const HealthSnapshot(heartRate: 68, hrv: 45, sleep: "7h 20m"),
    this.suggestedAction = const SuggestedAction(
      title: 'Box Breathing',
      description: 'A simple technique to maintain your steady state.',
      duration: '3 min',
    ),
    this.whyNowReasons = const [
      'Your heart rate is resting at a steady pace.',
      'You had a good amount of sleep last night.',
    ],
    this.selectedMood,
    this.baselineProgress = 0.4,
  });

  HomeState copyWith({
    String? currentWellbeing,
    HealthSnapshot? healthSnapshot,
    SuggestedAction? suggestedAction,
    List<String>? whyNowReasons,
    String? selectedMood,
    double? baselineProgress,
    bool clearMood = false,
  }) {
    return HomeState(
      currentWellbeing: currentWellbeing ?? this.currentWellbeing,
      healthSnapshot: healthSnapshot ?? this.healthSnapshot,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      whyNowReasons: whyNowReasons ?? this.whyNowReasons,
      selectedMood: clearMood ? null : (selectedMood ?? this.selectedMood),
      baselineProgress: baselineProgress ?? this.baselineProgress,
    );
  }
}
