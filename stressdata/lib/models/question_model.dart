class Question {
  final int id;
  final String questionText;
  final String category;
  final List<Option> options;

  Question({
    required this.id,
    required this.questionText,
    required this.category,
    required this.options,
  });
}

class Option {
  final String text;
  final int value;

  Option({
    required this.text,
    required this.value,
  });
}

class QuestionAnswer {
  final int questionId;
  final int selectedValue;
  final String selectedText;

  QuestionAnswer({
    required this.questionId,
    required this.selectedValue,
    required this.selectedText,
  });
}
