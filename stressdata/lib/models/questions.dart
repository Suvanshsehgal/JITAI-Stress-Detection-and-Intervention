import '../models/question_model.dart';

// WHO-5 Wellbeing Options
List<Option> who5Options = [
  Option(text: "At no time", value: 0),
  Option(text: "Some of the time", value: 1),
  Option(text: "Less than half of the time", value: 2),
  Option(text: "More than half of the time", value: 3),
  Option(text: "Most of the time", value: 4),
  Option(text: "All of the time", value: 5),
];

// Normal Stress Scoring
List<Option> stressOptions = [
  Option(text: "Not at all", value: 1),
  Option(text: "Slightly", value: 2),
  Option(text: "Moderately", value: 3),
  Option(text: "Very", value: 4),
  Option(text: "Extremely", value: 5),
];

// Reverse Stress Scoring
List<Option> reverseStressOptions = [
  Option(text: "Not at all", value: 5),
  Option(text: "Slightly", value: 4),
  Option(text: "Moderately", value: 3),
  Option(text: "Very", value: 2),
  Option(text: "Extremely", value: 1),
];

// Combined Questionnaire
List<Question> who5Questions = [

  // ===========================
  // WHO-5 WELLBEING QUESTIONS
  // ===========================

  Question(
    id: 1,
    questionText: "I have felt cheerful and in good spirits",
    category: "who5",
    options: who5Options,
  ),

  Question(
    id: 2,
    questionText: "I have felt calm and relaxed",
    category: "who5",
    options: who5Options,
  ),

  Question(
    id: 3,
    questionText: "I have felt active and vigorous",
    category: "who5",
    options: who5Options,
  ),

  Question(
    id: 4,
    questionText: "I woke up feeling fresh and rested",
    category: "who5",
    options: who5Options,
  ),

  Question(
    id: 5,
    questionText:
        "My daily life has been filled with things that interest me",
    category: "who5",
    options: who5Options,
  ),

  // ===========================
  // NORMAL STRESS QUESTIONS
  // ===========================

  Question(
    id: 6,
    questionText: "I feel stressed",
    category: "state_stress",
    options: stressOptions,
  ),

  Question(
    id: 7,
    questionText: "I feel mentally exhausted",
    category: "state_stress",
    options: stressOptions,
  ),

  // ===========================
  // REVERSE QUESTIONS
  // ===========================

  Question(
    id: 8,
    questionText: "I feel calm even in difficult situations",
    category: "reverse_stress",
    options: reverseStressOptions,
  ),

  Question(
    id: 9,
    questionText: "I am able to concentrate properly",
    category: "reverse_stress",
    options: reverseStressOptions,
  ),

  Question(
    id: 10,
    questionText: "I feel emotionally balanced",
    category: "reverse_stress",
    options: reverseStressOptions,
  ),
];

// Deprecated - kept for backward compatibility
List<Question> postStressQuestions = who5Questions.sublist(5, 10);