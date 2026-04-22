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
    displayDuration: 1200,
  ),
  PatternQuestion(
    id: 2,
    pattern: [1, 3, 5, 7],
    gridSize: 9,
    displayDuration: 1500,
  ),
  PatternQuestion(
    id: 3,
    pattern: [0, 2, 4, 6, 8],
    gridSize: 9,
    displayDuration: 1600,
  ),
  PatternQuestion(
    id: 4,
    pattern: [4, 10, 12, 14, 16],
    gridSize: 16,
    displayDuration: 1800,
  ),
  PatternQuestion(
    id: 5,
    pattern: [2, 4, 6, 8, 10, 12],
    gridSize: 16,
    displayDuration: 2000,
  ),
  PatternQuestion(
    id: 6,
    pattern: [0, 1, 3, 5, 6, 8],
    gridSize: 9,
    displayDuration: 1700,
  ),
  PatternQuestion(
    id: 7,
    pattern: [1, 5, 7, 9, 11, 13, 15],
    gridSize: 16,
    displayDuration: 2100,
  ),
  PatternQuestion(
    id: 8,
    pattern: [0, 1, 2, 3, 6, 7, 8],
    gridSize: 9,
    displayDuration: 1900,
  ),
  PatternQuestion(
    id: 9,
    pattern: [2, 4, 6, 8, 10, 12, 14],
    gridSize: 16,
    displayDuration: 2000,
  ),
  PatternQuestion(
    id: 10,
    pattern: [0, 1, 2, 4, 5, 6, 8],
    gridSize: 9,
    displayDuration: 1800,
  ),
  PatternQuestion(
    id: 11,
    pattern: [1, 3, 4, 7],
    gridSize: 9,
    displayDuration: 1300,
  ),
  PatternQuestion(
    id: 12,
    pattern: [0, 3, 5, 10, 12, 15],
    gridSize: 16,
    displayDuration: 1900,
  ),
  PatternQuestion(
    id: 13,
    pattern: [0, 2, 3, 5, 6, 7, 8],
    gridSize: 9,
    displayDuration: 1800,
  ),
  PatternQuestion(
    id: 14,
    pattern: [1, 2, 4, 6, 8, 9, 11, 13],
    gridSize: 16,
    displayDuration: 2200,
  ),
  PatternQuestion(
    id: 15,
    pattern: [0, 1, 2, 3, 4, 5, 6],
    gridSize: 9,
    displayDuration: 1900,
  ),
  PatternQuestion(
    id: 16,
    pattern: [0, 3, 6, 9, 12, 15],
    gridSize: 16,
    displayDuration: 1900,
  ),
  PatternQuestion(
    id: 17,
    pattern: [0, 1, 4, 5, 7, 8],
    gridSize: 9,
    displayDuration: 1600,
  ),
  PatternQuestion(
    id: 18,
    pattern: [0, 1, 2, 3, 4, 5, 8, 12],
    gridSize: 16,
    displayDuration: 2300,
  ),
  PatternQuestion(
    id: 19,
    pattern: [0, 1, 2, 5, 6, 7, 8],
    gridSize: 9,
    displayDuration: 1800,
  ),
  PatternQuestion(
    id: 20,
    pattern: [0, 1, 3, 5, 7, 10, 12, 14, 15],
    gridSize: 16,
    displayDuration: 2400,
  ),
];
