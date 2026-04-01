import 'dart:ui';

class StroopQuestion {
  final int id;
  final String word;
  final Color wordColor;
  final String correctAnswer;
  final List<String> options;

  StroopQuestion({
    required this.id,
    required this.word,
    required this.wordColor,
    required this.correctAnswer,
    required this.options,
  });
}

class StroopAnswer {
  final int questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTime; // in milliseconds

  StroopAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTime,
  });
}

// Stroop test questions - 15 questions for better assessment
List<StroopQuestion> stroopQuestions = [
  StroopQuestion(
    id: 1,
    word: "RED",
    wordColor: const Color(0xFF2196F3), // Blue
    correctAnswer: "Blue",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 2,
    word: "GREEN",
    wordColor: const Color(0xFFF44336), // Red
    correctAnswer: "Red",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 3,
    word: "YELLOW",
    wordColor: const Color(0xFF4CAF50), // Green
    correctAnswer: "Green",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 4,
    word: "BLUE",
    wordColor: const Color(0xFFFFEB3B), // Yellow
    correctAnswer: "Yellow",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 5,
    word: "RED",
    wordColor: const Color(0xFF4CAF50), // Green
    correctAnswer: "Green",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 6,
    word: "GREEN",
    wordColor: const Color(0xFFFFEB3B), // Yellow
    correctAnswer: "Yellow",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 7,
    word: "YELLOW",
    wordColor: const Color(0xFF2196F3), // Blue
    correctAnswer: "Blue",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 8,
    word: "BLUE",
    wordColor: const Color(0xFFF44336), // Red
    correctAnswer: "Red",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 9,
    word: "RED",
    wordColor: const Color(0xFFFFEB3B), // Yellow
    correctAnswer: "Yellow",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 10,
    word: "GREEN",
    wordColor: const Color(0xFF2196F3), // Blue
    correctAnswer: "Blue",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 11,
    word: "YELLOW",
    wordColor: const Color(0xFFF44336), // Red
    correctAnswer: "Red",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 12,
    word: "BLUE",
    wordColor: const Color(0xFF4CAF50), // Green
    correctAnswer: "Green",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 13,
    word: "RED",
    wordColor: const Color(0xFF2196F3), // Blue
    correctAnswer: "Blue",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 14,
    word: "GREEN",
    wordColor: const Color(0xFFF44336), // Red
    correctAnswer: "Red",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
  StroopQuestion(
    id: 15,
    word: "YELLOW",
    wordColor: const Color(0xFF4CAF50), // Green
    correctAnswer: "Green",
    options: ["Red", "Blue", "Green", "Yellow"],
  ),
];
