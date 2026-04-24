import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/questions.dart';
import '../models/question_model.dart';
import '../widget/custom_button.dart';
import '../services/session_manager.dart';
import '../services/database_service.dart';

class QuestionnaireTestScreen extends StatefulWidget {
  final int startIndex;
  final int endIndex;
  final Function(List<QuestionAnswer> answers) onComplete;

  const QuestionnaireTestScreen({
    super.key,
    required this.startIndex,
    required this.endIndex,
    required this.onComplete,
  });

  @override
  State<QuestionnaireTestScreen> createState() =>
      _QuestionnaireTestScreenState();
}

class _QuestionnaireTestScreenState extends State<QuestionnaireTestScreen> {
  int _currentQuestionIndex = 0;
  final List<QuestionAnswer> _answers = [];
  int? _selectedOptionIndex;
  final SessionManager _sessionManager = SessionManager();
  final DatabaseService _dbService = DatabaseService();
  bool _isSaving = false;

  List<Question> get _questions =>
      who5Questions.sublist(widget.startIndex, widget.endIndex);

  Question get _currentQuestion => _questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == _questions.length - 1;

  void _handleOptionSelected(int index) {
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  Future<void> _handleNext() async {
    if (_selectedOptionIndex == null) return;

    final option = _currentQuestion.options[_selectedOptionIndex!];
    _answers.add(QuestionAnswer(
      questionId: _currentQuestion.id,
      selectedValue: option.value,
      selectedText: option.text,
    ));

    if (_isLastQuestion) {
      // Save to database
      await _saveToDatabase();
      
      widget.onComplete(_answers);
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
      });
    }
  }

  Future<void> _saveToDatabase() async {
    setState(() => _isSaving = true);

    try {
      // Get session ID (must already exist)
      final sessionId = _sessionManager.sessionId;
      if (sessionId == null) {
        throw Exception('No active session - session must be created before saving WHO-5');
      }

      // Get logged-in user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      final userId = user.id;

      // Collect answers (q1-q5)
      final q1 = _answers[0].selectedValue;
      final q2 = _answers[1].selectedValue;
      final q3 = _answers[2].selectedValue;
      final q4 = _answers[3].selectedValue;
      final q5 = _answers[4].selectedValue;

      // Save to database
      await _dbService.insertWHO5(
        sessionId: sessionId,
        userId: userId,
        q1: q1,
        q2: q2,
        q3: q3,
        q4: q4,
        q5: q5,
      );

      debugPrint('✅ WHO-5 data saved successfully');
      debugPrint('   Session ID: $sessionId');
      debugPrint('   Answers: q1=$q1, q2=$q2, q3=$q3, q4=$q4, q5=$q5');
    } catch (e) {
      debugPrint('❌ Failed to save WHO-5 data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save questionnaire: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
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
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: const Color(0xFFE5D5CC),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF9B2B1A)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 32),
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
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
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
