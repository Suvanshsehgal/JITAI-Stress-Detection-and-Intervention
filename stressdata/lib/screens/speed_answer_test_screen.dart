import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/speed_answer_model.dart';
import '../services/session_manager.dart';

class SpeedAnswerTestScreen extends StatefulWidget {
  final Function(int score) onComplete;

  const SpeedAnswerTestScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SpeedAnswerTestScreen> createState() => _SpeedAnswerTestScreenState();
}

class _SpeedAnswerTestScreenState extends State<SpeedAnswerTestScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final List<SpeedAnswer> _answers = [];
  int _timeLeft = 3;
  Timer? _timer;
  DateTime? _questionStartTime;
  bool _showInstructions = true;
  int _score = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _answered = false;
  final SessionManager _sessionManager = SessionManager();
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  SpeedQuestion get _currentQuestion => speedQuestions[_currentQuestionIndex];
  bool get _isLastQuestion =>
      _currentQuestionIndex == speedQuestions.length - 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _startTest() {
    setState(() {
      _showInstructions = false;
    });
    _startQuestion();
  }

  void _startQuestion() {
    setState(() {
      _timeLeft = 3;
      _answered = false;
      _questionStartTime = DateTime.now();
    });

    _progressController.reset();
    _progressController.forward();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft == 1) {
          _shakeController.forward(from: 0);
        }
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_answered) return;
    _timer?.cancel();
    _progressController.stop();

    final responseTime =
        DateTime.now().difference(_questionStartTime!).inMilliseconds;
    _answers.add(SpeedAnswer(
      questionId: _currentQuestion.id,
      selectedAnswer: '',
      isCorrect: false,
      responseTime: responseTime,
    ));

    _streak = 0;
    _showFeedback(false, true);
  }

  void _handleAnswer(String answer) {
    if (_answered) return;

    setState(() {
      _answered = true;
    });

    _timer?.cancel();
    _progressController.stop();

    final responseTime =
        DateTime.now().difference(_questionStartTime!).inMilliseconds;
    final isCorrect = answer == _currentQuestion.correctAnswer;

    _answers.add(SpeedAnswer(
      questionId: _currentQuestion.id,
      selectedAnswer: answer,
      isCorrect: isCorrect,
      responseTime: responseTime,
    ));

    if (isCorrect) {
      _streak++;
      if (_streak > _maxStreak) {
        _maxStreak = _streak;
      }
      final timeBonus = (_timeLeft * 3);
      final streakBonus = (_streak > 1) ? (_streak * 5) : 0;
      final speedBonus = responseTime < 2000 ? 10 : 0;
      setState(() {
        _score += 15 + timeBonus + streakBonus + speedBonus;
      });
    } else {
      _streak = 0;
    }

    _showFeedback(isCorrect, false);
  }

  void _showFeedback(bool isCorrect, bool timeout) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EDE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                timeout
                    ? Icons.timer_off
                    : isCorrect
                        ? Icons.check_circle
                        : Icons.cancel,
                size: 64,
                color: timeout
                    ? Colors.orange
                    : isCorrect
                        ? Colors.green
                        : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                timeout
                    ? 'Time\'s Up!'
                    : isCorrect
                        ? 'Correct!'
                        : 'Wrong!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A08),
                ),
              ),
              if (_streak > 1 && isCorrect) ...[
                const SizedBox(height: 8),
                Text(
                  '⚡ ${_streak}x Streak!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B2B1A),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
        if (_isLastQuestion) {
          _completeTest();
        } else {
          setState(() {
            _currentQuestionIndex++;
          });
          _startQuestion();
        }
      }
    });
  }

  Future<void> _completeTest() async {
    // Save to database
    await _saveToDatabase();
    
    widget.onComplete(_score);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      // Calculate metrics
      final correctAnswers = _answers.where((a) => a.isCorrect).length;
      final totalQuestions = _answers.length;
      final totalResponseTime = _answers.fold<int>(
        0,
        (sum, answer) => sum + answer.responseTime,
      );
      final averageResponseTime = totalResponseTime / totalQuestions;
      final accuracy = correctAnswers / totalQuestions;
      
      // Count errors
      final commissionErrors = _answers.where((a) => !a.isCorrect && a.selectedAnswer.isNotEmpty).length;
      final omissionErrors = _answers.where((a) => a.selectedAnswer.isEmpty).length;

      // Store metrics in SessionManager (will be saved after all cognitive tests)
      _sessionManager.storeSpeedMetrics(
        accuracy: accuracy,
        avgResponseTime: averageResponseTime,
        streakMax: _maxStreak,
        commissionErrors: commissionErrors,
        omissionErrors: omissionErrors,
      );

      debugPrint('✅ Speed Answer metrics stored in SessionManager');
    } catch (e) {
      debugPrint('❌ Failed to store Speed Answer metrics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to store test metrics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showInstructions) {
      return _buildInstructions();
    }

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
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildProgressBar(),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: _buildTimer(),
                ),
                const SizedBox(height: 32),
                _buildQuestionDisplay(),
                const SizedBox(height: 32),
                _buildOptions(),
                const Spacer(),
                _buildScoreDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Speed Answer Test',
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
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2196F3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flash_on,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'How to Play',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A0A08),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildInstructionCard(
                            '1',
                            'Answer Fast',
                            'Solve math & logic problems quickly',
                            Icons.calculate,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionCard(
                            '2',
                            '3 Seconds Each',
                            'Think fast, answer faster!',
                            Icons.timer,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionCard(
                            '3',
                            'Speed Bonus',
                            'Answer in under 2 seconds for extra points',
                            Icons.bolt,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Example:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A0A08),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '7 + 8 = ?',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A0A08),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Answer: 15 ✓',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
      String number, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A08),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: const Color(0xFF2196F3),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Speed Answer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0A08),
              ),
            ),
            Text(
              'Question ${_currentQuestionIndex + 1}/${speedQuestions.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        if (_streak > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_streak}x',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              '${((_currentQuestionIndex + 1) / speedQuestions.length * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / speedQuestions.length,
          backgroundColor: const Color(0xFFE5D5CC),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: 1 - _progressController.value,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFE5D5CC),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeLeft <= 1 ? Colors.red : const Color(0xFF2196F3),
                    ),
                  ),
                ),
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color:
                        _timeLeft <= 1 ? Colors.red : const Color(0xFF1A0A08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'seconds left',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionDisplay() {
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (_currentQuestion.type) {
      case SpeedQuestionType.math:
        typeIcon = Icons.calculate;
        typeColor = const Color(0xFF2196F3);
        typeLabel = 'Math';
        break;
      case SpeedQuestionType.logic:
        typeIcon = Icons.psychology;
        typeColor = const Color(0xFF9C27B0);
        typeLabel = 'Logic';
        break;
      case SpeedQuestionType.pattern:
        typeIcon = Icons.pattern;
        typeColor = const Color(0xFF4CAF50);
        typeLabel = 'Pattern';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, size: 16, color: typeColor),
                const SizedBox(width: 4),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentQuestion.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A0A08),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: _currentQuestion.options.map((option) {
        return InkWell(
          onTap: _answered ? null : () => _handleAnswer(option),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A08),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.stars,
            color: Color(0xFF2196F3),
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Score: ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A0A08),
            ),
          ),
          Text(
            '$_score',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }
}
