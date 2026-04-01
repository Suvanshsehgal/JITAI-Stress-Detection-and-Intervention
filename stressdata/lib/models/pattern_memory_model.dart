class PatternQuestion {
  final int id;
  final List<int> pattern;
  final int gridSize;
  final int displayDuration;

  PatternQuestion({
    required this.id,
    required this.pattern,
    required this.gridSize,
    required this.displayDuration,
  });
}

class PatternAnswer {
  final int questionId;
  final List<int> selectedPattern;
  final bool isCorrect;
  final int responseTime;

  PatternAnswer({
    required this.questionId,
    required this.selectedPattern,
    required this.isCorrect,
    required this.responseTime,
  });
}

List<PatternQuestion> patternQuestions = [
  PatternQuestion(
    id: 1,
    pattern: [0, 4, 8],
    gridSize: 9,
    displayDuration: 1500,
  ),
  PatternQuestion(
    id: 2,
    pattern: [1, 3, 5, 7],
    gridSize: 9,
    displayDuration: 1800,
  ),
  PatternQuestion(
    id: 3,
    pattern: [0, 2, 6, 8],
    gridSize: 9,
    displayDuration: 1800,
  ),
  PatternQuestion(
    id: 4,
    pattern: [4, 10, 12, 14, 16],
    gridSize: 16,
    displayDuration: 2200,
  ),
  PatternQuestion(
    id: 5,
    pattern: [2, 4, 6, 10, 12],
    gridSize: 16,
    displayDuration: 2200,
  ),
  PatternQuestion(
    id: 6,
    pattern: [0, 3, 5, 6, 8],
    gridSize: 9,
    displayDuration: 2000,
  ),
  PatternQuestion(
    id: 7,
    pattern: [1, 5, 7, 11, 13, 15],
    gridSize: 16,
    displayDuration: 2500,
  ),
  PatternQuestion(
    id: 8,
    pattern: [0, 1, 2, 6, 7, 8],
    gridSize: 9,
    displayDuration: 2300,
  ),
  PatternQuestion(
    id: 9,
    pattern: [2, 4, 8, 10, 14],
    gridSize: 16,
    displayDuration: 2200,
  ),
  PatternQuestion(
    id: 10,
    pattern: [0, 2, 4, 6, 8],
    gridSize: 9,
    displayDuration: 2000,
  ),
];
