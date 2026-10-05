import 'dart:ui';

enum StroopQuestionType { classic, reverse, spatial, auditory }

enum ArrowDirection { up, down, left, right }

enum PitchPosition { high, low }

class StroopQuestion {
  final int id;
  final StroopQuestionType type;
  final String word;
  final Color wordColor;
  final String correctAnswer;
  final List<String> options;
  final ArrowDirection? arrowDirection;
  final PitchPosition? pitchPosition;

  StroopQuestion({
    required this.id,
    this.type = StroopQuestionType.classic,
    required this.word,
    required this.wordColor,
    required this.correctAnswer,
    required this.options,
    this.arrowDirection,
    this.pitchPosition,
  });
}

class StroopAnswer {
  final int questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTime;

  StroopAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTime,
  });
}

List<StroopQuestion> stroopQuestions = [
  // ── CLASSIC (color-word interference) ──
  StroopQuestion(id: 1, word: "RED", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 2, word: "GREEN", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 3, word: "YELLOW", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 4, word: "BLUE", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 5, word: "RED", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 6, word: "GREEN", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 7, word: "YELLOW", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 8, word: "BLUE", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 9, word: "RED", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 10, word: "GREEN", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 11, word: "YELLOW", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 12, word: "BLUE", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 13, word: "RED", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 14, word: "GREEN", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 15, word: "YELLOW", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 16, word: "BLUE", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 17, word: "RED", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 18, word: "GREEN", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 19, word: "YELLOW", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 20, word: "BLUE", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),

  // ── REVERSE (color patch → name the color) ──
  StroopQuestion(id: 21, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 22, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 23, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 24, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 25, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 26, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 27, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFF4CAF50), correctAnswer: "Green", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 28, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFFFFEB3B), correctAnswer: "Yellow", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 29, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFFF44336), correctAnswer: "Red", options: ["Red", "Blue", "Green", "Yellow"]),
  StroopQuestion(id: 30, type: StroopQuestionType.reverse, word: "??", wordColor: Color(0xFF2196F3), correctAnswer: "Blue", options: ["Red", "Blue", "Green", "Yellow"]),

  // ── SPATIAL (arrow direction vs direction word) ──
  StroopQuestion(id: 31, type: StroopQuestionType.spatial, word: "DOWN", wordColor: Color(0xFF1A0A08), correctAnswer: "Up", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.up),
  StroopQuestion(id: 32, type: StroopQuestionType.spatial, word: "UP", wordColor: Color(0xFF1A0A08), correctAnswer: "Down", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.down),
  StroopQuestion(id: 33, type: StroopQuestionType.spatial, word: "RIGHT", wordColor: Color(0xFF1A0A08), correctAnswer: "Left", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.left),
  StroopQuestion(id: 34, type: StroopQuestionType.spatial, word: "LEFT", wordColor: Color(0xFF1A0A08), correctAnswer: "Right", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.right),
  StroopQuestion(id: 35, type: StroopQuestionType.spatial, word: "UP", wordColor: Color(0xFF1A0A08), correctAnswer: "Up", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.up),
  StroopQuestion(id: 36, type: StroopQuestionType.spatial, word: "DOWN", wordColor: Color(0xFF1A0A08), correctAnswer: "Down", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.down),
  StroopQuestion(id: 37, type: StroopQuestionType.spatial, word: "RIGHT", wordColor: Color(0xFF1A0A08), correctAnswer: "Right", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.right),
  StroopQuestion(id: 38, type: StroopQuestionType.spatial, word: "LEFT", wordColor: Color(0xFF1A0A08), correctAnswer: "Left", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.left),
  StroopQuestion(id: 39, type: StroopQuestionType.spatial, word: "DOWN", wordColor: Color(0xFF1A0A08), correctAnswer: "Up", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.up),
  StroopQuestion(id: 40, type: StroopQuestionType.spatial, word: "UP", wordColor: Color(0xFF1A0A08), correctAnswer: "Down", options: ["Up", "Down", "Left", "Right"], arrowDirection: ArrowDirection.down),

  // ── AUDITORY (visual: position of "HIGH"/"LOW") ──
  StroopQuestion(id: 41, type: StroopQuestionType.auditory, word: "HIGH", wordColor: Color(0xFF1A0A08), correctAnswer: "Low", options: ["High", "Low"], pitchPosition: PitchPosition.low),
  StroopQuestion(id: 42, type: StroopQuestionType.auditory, word: "LOW", wordColor: Color(0xFF1A0A08), correctAnswer: "High", options: ["High", "Low"], pitchPosition: PitchPosition.high),
  StroopQuestion(id: 43, type: StroopQuestionType.auditory, word: "HIGH", wordColor: Color(0xFF1A0A08), correctAnswer: "Low", options: ["High", "Low"], pitchPosition: PitchPosition.low),
  StroopQuestion(id: 44, type: StroopQuestionType.auditory, word: "LOW", wordColor: Color(0xFF1A0A08), correctAnswer: "High", options: ["High", "Low"], pitchPosition: PitchPosition.high),
  StroopQuestion(id: 45, type: StroopQuestionType.auditory, word: "HIGH", wordColor: Color(0xFF1A0A08), correctAnswer: "High", options: ["High", "Low"], pitchPosition: PitchPosition.high),
  StroopQuestion(id: 46, type: StroopQuestionType.auditory, word: "LOW", wordColor: Color(0xFF1A0A08), correctAnswer: "Low", options: ["High", "Low"], pitchPosition: PitchPosition.low),
  StroopQuestion(id: 47, type: StroopQuestionType.auditory, word: "HIGH", wordColor: Color(0xFF1A0A08), correctAnswer: "Low", options: ["High", "Low"], pitchPosition: PitchPosition.low),
  StroopQuestion(id: 48, type: StroopQuestionType.auditory, word: "LOW", wordColor: Color(0xFF1A0A08), correctAnswer: "High", options: ["High", "Low"], pitchPosition: PitchPosition.high),
];
