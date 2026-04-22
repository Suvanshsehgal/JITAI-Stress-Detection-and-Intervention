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
    question: "13 + 19 = ?",
    correctAnswer: "32",
    options: ["30", "31", "32", "33"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 2,
    question: "47 - 28 = ?",
    correctAnswer: "19",
    options: ["17", "18", "19", "20"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 3,
    question: "9 × 7 = ?",
    correctAnswer: "63",
    options: ["56", "63", "70", "72"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 4,
    question: "What comes next?\n3, 9, 27, 81, ?",
    correctAnswer: "243",
    options: ["162", "216", "243", "324"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 5,
    question: "72 ÷ 8 = ?",
    correctAnswer: "9",
    options: ["7", "8", "9", "10"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 6,
    question: "Which is larger?",
    correctAnswer: "89",
    options: ["78", "83", "89", "87"],
    type: SpeedQuestionType.logic,
  ),
  SpeedQuestion(
    id: 7,
    question: "25 + 37 = ?",
    correctAnswer: "62",
    options: ["60", "61", "62", "63"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 8,
    question: "64 - 39 = ?",
    correctAnswer: "25",
    options: ["23", "24", "25", "26"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 9,
    question: "What comes next?\n2, 4, 8, 16, ?",
    correctAnswer: "32",
    options: ["24", "28", "32", "36"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 10,
    question: "12 × 6 = ?",
    correctAnswer: "72",
    options: ["66", "68", "72", "76"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 11,
    question: "Which is smaller?",
    correctAnswer: "43",
    options: ["43", "51", "58", "67"],
    type: SpeedQuestionType.logic,
  ),
  SpeedQuestion(
    id: 12,
    question: "96 ÷ 12 = ?",
    correctAnswer: "8",
    options: ["6", "7", "8", "9"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 13,
    question: "48 + 35 = ?",
    correctAnswer: "83",
    options: ["81", "82", "83", "84"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 14,
    question: "What comes next?\n1, 4, 9, 16, ?",
    correctAnswer: "25",
    options: ["20", "22", "25", "28"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 15,
    question: "11 × 9 = ?",
    correctAnswer: "99",
    options: ["88", "90", "99", "108"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 16,
    question: "85 - 47 = ?",
    correctAnswer: "38",
    options: ["36", "37", "38", "39"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 17,
    question: "Which is larger?",
    correctAnswer: "134",
    options: ["127", "129", "134", "131"],
    type: SpeedQuestionType.logic,
  ),
  SpeedQuestion(
    id: 18,
    question: "13 × 8 = ?",
    correctAnswer: "104",
    options: ["96", "100", "104", "112"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 19,
    question: "What comes next?\n5, 15, 45, 135, ?",
    correctAnswer: "405",
    options: ["270", "315", "405", "540"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 20,
    question: "144 ÷ 12 = ?",
    correctAnswer: "12",
    options: ["10", "11", "12", "13"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 21,
    question: "67 + 58 = ?",
    correctAnswer: "125",
    options: ["123", "124", "125", "126"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 22,
    question: "Which is smaller?",
    correctAnswer: "76",
    options: ["76", "89", "94", "102"],
    type: SpeedQuestionType.logic,
  ),
  SpeedQuestion(
    id: 23,
    question: "What comes next?\n100, 50, 25, 12.5, ?",
    correctAnswer: "6.25",
    options: ["5", "6", "6.25", "7"],
    type: SpeedQuestionType.pattern,
  ),
  SpeedQuestion(
    id: 24,
    question: "15 × 7 = ?",
    correctAnswer: "105",
    options: ["98", "100", "105", "110"],
    type: SpeedQuestionType.math,
  ),
  SpeedQuestion(
    id: 25,
    question: "156 ÷ 13 = ?",
    correctAnswer: "12",
    options: ["10", "11", "12", "13"],
    type: SpeedQuestionType.math,
  ),
];
