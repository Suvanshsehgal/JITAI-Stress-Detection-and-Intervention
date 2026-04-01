import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/questions.dart';
import '../models/question_model.dart';
import '../widget/custom_button.dart';
import 'stroop_test_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  final List<QuestionAnswer> _answers = [];
  int? _selectedOptionIndex;

  Question get _currentQuestion => who5Questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == who5Questions.length - 1;

  void _handleOptionSelected(int index) {
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _handleNext() {
    if (_selectedOptionIndex == null) return;

    // Save the answer
    final option = _currentQuestion.options[_selectedOptionIndex!];
    _answers.add(QuestionAnswer(
      questionId: _currentQuestion.id,
      selectedValue: option.value,
      selectedText: option.text,
    ));

    // After question 5, navigate to Stroop test
    if (_currentQuestionIndex == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StroopTestScreen(
            onComplete: (score) {
              // Handle stroop test completion
              print('Stroop test completed with score: $score');
            },
          ),
        ),
      );
      return;
    }

    if (_isLastQuestion) {
      // Navigate to results or home
      _showCompletionDialog();
    } else {
      // Move to next question
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
      });
    }
  }

  void _showCompletionDialog() {
    final totalScore = _answers.fold<int>(0, (sum, answer) => sum + answer.selectedValue);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Questionnaire Complete!',
          style: TextStyle(
            color: Color(0xFF1A0A08),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your total score: $totalScore/${who5Questions.length * 5}',
          style: const TextStyle(
            color: Color(0xFF1A0A08),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF9B2B1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5EDE8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${who5Questions.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0A08),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF1A0A08),
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / who5Questions.length,
                  backgroundColor: const Color(0xFFE5D5CC),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B2B1A)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),

                const SizedBox(height: 32),

                // Question text
                Text(
                  _currentQuestion.questionText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A08),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 32),

                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      final option = _currentQuestion.options[index];
                      final isSelected = _selectedOptionIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => _handleOptionSelected(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF9B2B1A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF9B2B1A)
                                    : const Color(0xFFE5D5CC),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF9B2B1A),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Color(0xFF9B2B1A),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1A0A08),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Next button
                CustomButton(
                  text: _isLastQuestion ? 'Submit' : 'Next',
                  onPressed: _selectedOptionIndex != null ? _handleNext : () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
