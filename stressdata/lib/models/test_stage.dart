enum TestStage {
  ppgPre,
  questionnairePre,
  stroopTest,
  speedAnswerTest,
  patternMemoryTest,
  questionnairePost,
  ppgPost,
  completed,
}

class TestProgress {
  final TestStage currentStage;
  final Map<TestStage, bool> completedStages;
  final Map<String, dynamic> results;

  TestProgress({
    required this.currentStage,
    required this.completedStages,
    required this.results,
  });

  TestProgress copyWith({
    TestStage? currentStage,
    Map<TestStage, bool>? completedStages,
    Map<String, dynamic>? results,
  }) {
    return TestProgress(
      currentStage: currentStage ?? this.currentStage,
      completedStages: completedStages ?? this.completedStages,
      results: results ?? this.results,
    );
  }

  static TestProgress initial() {
    return TestProgress(
      currentStage: TestStage.ppgPre,
      completedStages: {},
      results: {},
    );
  }
}
