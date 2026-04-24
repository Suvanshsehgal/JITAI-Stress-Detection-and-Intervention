import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_stage.dart';
import '../widget/custom_button.dart';
import '../services/session_manager.dart';
import 'ppg_test_screen.dart';
import 'questionnaire_test_screen.dart';
import 'stroop_test_screen.dart';
import 'speed_answer_test_screen.dart';
import 'pattern_memory_test_screen.dart';

class TestMapScreen extends StatefulWidget {
  const TestMapScreen({super.key});

  @override
  State<TestMapScreen> createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  TestProgress _progress = TestProgress.initial();
  final SessionManager _sessionManager = SessionManager();
  bool _isInitializing = false;

  final List<Map<String, dynamic>> _testStages = [
    {
      'stage': TestStage.ppgPre,
      'title': 'PPG Heart Sense',
      'subtitle': 'Pre-test measurement',
      'icon': Icons.favorite,
    },
    {
      'stage': TestStage.questionnairePre,
      'title': 'Questionnaire',
      'subtitle': 'Questions 1-5',
      'icon': Icons.quiz,
    },
    {
      'stage': TestStage.stroopTest,
      'title': 'Stroop Word Test',
      'subtitle': 'Stress stimuli activity',
      'icon': Icons.text_fields,
    },
    {
      'stage': TestStage.speedAnswerTest,
      'title': 'Speed Answer Test',
      'subtitle': 'Stress stimuli activity',
      'icon': Icons.speed,
    },
    {
      'stage': TestStage.patternMemoryTest,
      'title': 'Pattern Memory Test',
      'subtitle': 'Stress stimuli activity',
      'icon': Icons.grid_on,
    },
    {
      'stage': TestStage.questionnairePost,
      'title': 'Questionnaire',
      'subtitle': 'Questions 6-10',
      'icon': Icons.quiz,
    },
    {
      'stage': TestStage.ppgPost,
      'title': 'PPG Heart Sense',
      'subtitle': 'Post-test measurement',
      'icon': Icons.favorite,
    },
  ];

  Future<void> _startTest() async {
    // Debug: Check auth state
    debugPrint('🔍 Starting test - checking auth state...');
    debugPrint('🔍 User ID: ${_sessionManager.userId}');
    debugPrint('🔍 Has active session: ${_sessionManager.hasActiveSession}');
    
    // Start session if not already started
    if (!_sessionManager.hasActiveSession) {
      setState(() => _isInitializing = true);
      
      final success = await _sessionManager.startSession();
      
      setState(() => _isInitializing = false);
      
      if (!success) {
        if (mounted) {
          // Check if user is logged in
          final userId = _sessionManager.userId;
          final errorMessage = userId == null
              ? 'Please log in to start the test.'
              : 'Failed to start test session. Please check your internet connection and try again.';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: userId == null
                  ? SnackBarAction(
                      label: 'Login',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop(); // Go back to home
                      },
                    )
                  : null,
            ),
          );
        }
        return;
      }
    }
    
    _navigateToStage(_progress.currentStage);
  }

  void _navigateToStage(TestStage stage) async {
    late Widget screen;

    switch (stage) {
      case TestStage.ppgPre:
        screen = PpgTestScreen(
          isPre: true,
          onComplete: (bpm) => _onStageComplete(stage, {'bpm': bpm}),
        );
        break;
      case TestStage.questionnairePre:
        screen = QuestionnaireTestScreen(
          startIndex: 0,
          endIndex: 5,
          onComplete: (answers) => _onStageComplete(stage, {'answers': answers}),
        );
        break;
      case TestStage.stroopTest:
        screen = StroopTestScreen(
          onComplete: (score) => _onStageComplete(stage, {'score': score}),
        );
        break;
      case TestStage.speedAnswerTest:
        screen = SpeedAnswerTestScreen(
          onComplete: (score) => _onStageComplete(stage, {'score': score}),
        );
        break;
      case TestStage.patternMemoryTest:
        screen = PatternMemoryTestScreen(
          onComplete: (score) => _onStageComplete(stage, {'score': score}),
        );
        break;
      case TestStage.questionnairePost:
        screen = QuestionnaireTestScreen(
          startIndex: 5,
          endIndex: 10,
          onComplete: (answers) => _onStageComplete(stage, {'answers': answers}),
        );
        break;
      case TestStage.ppgPost:
        screen = PpgTestScreen(
          isPre: false,
          onComplete: (bpm) => _onStageComplete(stage, {'bpm': bpm}),
        );
        break;
      case TestStage.completed:
        _showCompletionDialog();
        return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _onStageComplete(TestStage stage, Map<String, dynamic> result) {
    setState(() {
      _progress.completedStages[stage] = true;
      _progress.results[stage.name] = result;

      // Move to next stage
      final currentIndex = TestStage.values.indexOf(stage);
      if (currentIndex < TestStage.values.length - 1) {
        _progress = _progress.copyWith(
          currentStage: TestStage.values[currentIndex + 1],
        );
      } else {
        _progress = _progress.copyWith(
          currentStage: TestStage.completed,
        );
      }
    });

    // Auto-navigate to next stage or show completion
    if (_progress.currentStage == TestStage.completed) {
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    // End session
    await _sessionManager.endSession();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Test Complete!',
          style: TextStyle(
            color: Color(0xFF1A0A08),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You have completed all test stages. Your results have been saved.',
          style: TextStyle(
            color: Color(0xFF1A0A08),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
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
                    const Text(
                      'Test Overview',
                      style: TextStyle(
                        fontSize: 24,
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

                const SizedBox(height: 24),

                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timeline,
                        color: Color(0xFF9B2B1A),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_progress.completedStages.length}/${_testStages.length} stages completed',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A0A08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Test stages map
                Expanded(
                  child: ListView.builder(
                    itemCount: _testStages.length,
                    itemBuilder: (context, index) {
                      final stageData = _testStages[index];
                      final stage = stageData['stage'] as TestStage;
                      final isCompleted = _progress.completedStages[stage] ?? false;
                      final isCurrent = _progress.currentStage == stage;
                      final isLocked = !isCompleted && !isCurrent;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            // Stage number and connector
                            Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFF9B2B1A)
                                        : isCurrent
                                            ? const Color(0xFF9B2B1A).withValues(alpha: 0.2)
                                            : const Color(0xFFE5D5CC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : isLocked
                                            ? const Icon(
                                                Icons.lock,
                                                color: Color(0xFF999999),
                                                size: 24,
                                              )
                                            : Icon(
                                                stageData['icon'] as IconData,
                                                color: const Color(0xFF9B2B1A),
                                                size: 24,
                                              ),
                                  ),
                                ),
                                if (index < _testStages.length - 1)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: isCompleted
                                        ? const Color(0xFF9B2B1A)
                                        : const Color(0xFFE5D5CC),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // Stage info
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF9B2B1A)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stageData['title'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isLocked
                                            ? const Color(0xFF999999)
                                            : const Color(0xFF1A0A08),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stageData['subtitle'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isLocked
                                            ? const Color(0xFF999999)
                                            : const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Start/Continue button
                _isInitializing
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: _progress.completedStages.isEmpty
                            ? 'Start Test'
                            : _progress.currentStage == TestStage.completed
                                ? 'View Results'
                                : 'Continue Test',
                        onPressed: _startTest,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
