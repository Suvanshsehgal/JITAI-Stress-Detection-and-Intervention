enum BuddyTone { gentle, playful, straightTalking }

class OnboardingState {
  final String buddyName;
  final BuddyTone tone;
  final Set<String> goals;
  final Set<String> dataPrefs;
  final bool isCompleted;

  const OnboardingState({
    this.buddyName = 'Pip',
    this.tone = BuddyTone.gentle,
    this.goals = const {},
    this.dataPrefs = const {},
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    String? buddyName,
    BuddyTone? tone,
    Set<String>? goals,
    Set<String>? dataPrefs,
    bool? isCompleted,
  }) {
    return OnboardingState(
      buddyName: buddyName ?? this.buddyName,
      tone: tone ?? this.tone,
      goals: goals ?? this.goals,
      dataPrefs: dataPrefs ?? this.dataPrefs,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
