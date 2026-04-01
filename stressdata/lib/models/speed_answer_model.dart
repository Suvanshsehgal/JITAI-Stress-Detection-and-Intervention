class SpeedQuestion {
  final int id;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final SpeedQuestionType type;

  SpeedQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.type,
  });
}

enum SpeedQuestionType {
  math,
  logic,
  pattern,
}

class SpeedAnswer {
  final int questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTime;

  SpeedAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTime,
  });
}

List<SpeedQuestion> speedQuestions = [
  SpeedQuestion(
    id: 1,
    question: "7 + 8 = ?",
    correctAnswer: "15",
    options: ["13", "14", "15", "16"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 2,
    question: "12 - 5 = ?",
    correctAnswer: "7",
    options: ["6", "7", "8", "9"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 3,
    question: "6 × 4 = ?",
    correctAnswer: "24",
    options: ["20", "22", "24", "26"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 4,
    question: "What comes next?\n2, 4, 6, 8, ?",
    correctAnswer: "10",
    options: ["9", "10", "11", "12"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 5,
    question: "15 ÷ 3 = ?",
    correctAnswer: "5",
    options: ["3", "4", "5", "6"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 6,
    question: "Which is larger?",
    correctAnswer: "45",
    options: ["34", "45", "38", "42"],
    type: SpeedQuestionType.logic,
  ),
  SpeedQuestion(
    id: 7,
    question: "9 + 6 = ?",
    correctAnswer: "15",
    options: ["13", "14", "15", "16"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 8,
    question: "20 - 7 = ?",
    correctAnswer: "13",
    options: ["11", "12", "13", "14"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 9,
    question: "What comes next?\n5, 10, 15, 20, ?",
    correctAnswer: "25",
    options: ["22", "23", "24", "25"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 10,
    question: "8 × 3 = ?",
    correctAnswer: "24",
    options: ["21", "22", "23", "24"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 11,
    question: "Which is smaller?",
    correctAnswer: "17",
    options: ["17", "23", "29", "31"],
    type: SpeedQuestionType.logic,
  ),
  SpeedQuestion(
    id: 12,
    question: "18 ÷ 2 = ?",
    correctAnswer: "9",
    options: ["7", "8", "9", "10"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 13,
    question: "11 + 9 = ?",
    correctAnswer: "20",
    options: ["18", "19", "20", "21"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 14,
    question: "What comes next?\n1, 3, 5, 7, ?",
    correctAnswer: "9",
    options: ["8", "9", "10", "11"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 15,
    question: "7 × 5 = ?",
    correctAnswer: "35",
    options: ["30", "32", "35", "40"],
    type: SpeedQuestionType.math,
  ),
];
