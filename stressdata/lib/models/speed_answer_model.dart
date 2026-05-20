import 'dart:math';

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
    options: ["32", "30", "31", "33"], // 1st
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 2,
    question: "47 - 28 = ?",
    correctAnswer: "19",
    options: ["17", "19", "18", "20"], // 2nd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 3,
    question: "9 × 7 = ?",
    correctAnswer: "63",
    options: ["56", "70", "72", "63"], // 4th
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 4,
    question: "What comes next?\n3, 9, 27, 81, ?",
    correctAnswer: "243",
    options: ["162", "243", "216", "324"], // 2nd
    type: SpeedQuestionType.pattern,
  ),

  SpeedQuestion(
    id: 5,
    question: "72 ÷ 8 = ?",
    correctAnswer: "9",
    options: ["7", "8", "10", "9"], // 4th
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 6,
    question: "Which is larger?",
    correctAnswer: "89",
    options: ["78", "89", "83", "87"], // 2nd
    type: SpeedQuestionType.logic,
  ),

  SpeedQuestion(
    id: 7,
    question: "25 + 37 = ?",
    correctAnswer: "62",
    options: ["60", "61", "62", "63"], // 3rd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 8,
    question: "64 - 39 = ?",
    correctAnswer: "25",
    options: ["25", "23", "24", "26"], // 1st
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 9,
    question: "What comes next?\n2, 4, 8, 16, ?",
    correctAnswer: "32",
    options: ["24", "28", "36", "32"], // 4th
    type: SpeedQuestionType.pattern,
  ),

  SpeedQuestion(
    id: 10,
    question: "12 × 6 = ?",
    correctAnswer: "72",
    options: ["66", "72", "68", "76"], // 2nd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 11,
    question: "Which is smaller?",
    correctAnswer: "43",
    options: ["51", "58", "43", "67"], // 3rd
    type: SpeedQuestionType.logic,
  ),

  SpeedQuestion(
    id: 12,
    question: "96 ÷ 12 = ?",
    correctAnswer: "8",
    options: ["6", "8", "7", "9"], // 2nd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 13,
    question: "48 + 35 = ?",
    correctAnswer: "83",
    options: ["81", "82", "84", "83"], // 4th
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 14,
    question: "What comes next?\n1, 4, 9, 16, ?",
    correctAnswer: "25",
    options: ["25", "20", "22", "28"], // 1st
    type: SpeedQuestionType.pattern,
  ),

  SpeedQuestion(
    id: 15,
    question: "11 × 9 = ?",
    correctAnswer: "99",
    options: ["88", "99", "90", "108"], // 2nd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 16,
    question: "85 - 47 = ?",
    correctAnswer: "38",
    options: ["36", "37", "39", "38"], // 4th
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 17,
    question: "Which is larger?",
    correctAnswer: "134",
    options: ["134", "127", "129", "131"], // 1st
    type: SpeedQuestionType.logic,
  ),

  SpeedQuestion(
    id: 18,
    question: "13 × 8 = ?",
    correctAnswer: "104",
    options: ["96", "100", "104", "112"], // 3rd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 19,
    question: "What comes next?\n5, 15, 45, 135, ?",
    correctAnswer: "405",
    options: ["270", "405", "315", "540"], // 2nd
    type: SpeedQuestionType.pattern,
  ),

  SpeedQuestion(
    id: 20,
    question: "144 ÷ 12 = ?",
    correctAnswer: "12",
    options: ["10", "11", "13", "12"], // 4th
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 21,
    question: "67 + 58 = ?",
    correctAnswer: "125",
    options: ["123", "125", "124", "126"], // 2nd
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 22,
    question: "Which is smaller?",
    correctAnswer: "76",
    options: ["89", "94", "76", "102"], // 3rd
    type: SpeedQuestionType.logic,
  ),

  SpeedQuestion(
    id: 23,
    question: "What comes next?\n100, 50, 25, 12.5, ?",
    correctAnswer: "6.25",
    options: ["5", "6.25", "6", "7"], // 2nd
    type: SpeedQuestionType.pattern,
  ),

  SpeedQuestion(
    id: 24,
    question: "15 × 7 = ?",
    correctAnswer: "105",
    options: ["98", "100", "110", "105"], // 4th
    type: SpeedQuestionType.math,
  ),

  SpeedQuestion(
    id: 25,
    question: "156 ÷ 13 = ?",
    correctAnswer: "12",
    options: ["12", "10", "11", "13"], // 1st
    type: SpeedQuestionType.math,
  ),
];