import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stroop_test_model.dart';
import '../services/session_manager.dart';
import '../services/sensor_capture_service.dart';

class StroopTestScreen extends StatefulWidget {
  final Function(int score) onComplete;
  final SensorCaptureService sensorService;

  const StroopTestScreen({
    super.key,
    required this.onComplete,
    required this.sensorService,
  });

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen>
    with TickerProviderStateMixin {
  late final List<StroopQuestion> _questions;

  int _currentQuestionIndex = 0;
  final List<StroopAnswer> _answers = [];
  int _timeLeft = 3;
  Timer? _timer;
  DateTime? _questionStartTime;
  bool _showInstructions = true;
  int _score = 0;
  int _streak = 0;
  bool _answered = false;
  final SessionManager _sessionManager = SessionManager();
  late AnimationController _pulseController;
  late AnimationController _progressController;

  StroopQuestion get _currentQuestion => _questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == _questions.length - 1;

  String get _promptText {
    switch (_currentQuestion.type) {
      case StroopQuestionType.classic:
        return 'What COLOR is this word?';
      case StroopQuestionType.reverse:
        return 'What color is shown?';
      case StroopQuestionType.spatial:
        return 'Which direction does the arrow point?';
      case StroopQuestionType.auditory:
        return 'Where is the text positioned?';
    }
  }

  @override
  void initState() {
    super.initState();
    final pool = List<StroopQuestion>.from(stroopQuestions)..shuffle(Random());
    _questions = pool.take(10).toList();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  void _startTest() {
    setState(() => _showInstructions = false);
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
        setState(() => _timeLeft--);
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
    _answers.add(StroopAnswer(
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
    final now = DateTime.now();
    final responseTime = now.difference(_questionStartTime!).inMilliseconds;

    setState(() => _answered = true);
    _timer?.cancel();
    _progressController.stop();

    final isCorrect = answer == _currentQuestion.correctAnswer;
    _answers.add(StroopAnswer(
      questionId: _currentQuestion.id,
      selectedAnswer: answer,
      isCorrect: isCorrect,
      responseTime: responseTime,
    ));

    if (isCorrect) {
      _streak++;
      final timeBonus = _timeLeft * 2;
      final streakBonus = (_streak > 1) ? (_streak * 5) : 0;
      setState(() => _score += 10 + timeBonus + streakBonus);
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
                    ? "Time's Up!"
                    : isCorrect
                        ? 'Correct!'
                        : 'Wrong!',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A08)),
              ),
              if (_streak > 1 && isCorrect) ...[
                const SizedBox(height: 8),
                Text('🔥 ${_streak}x Streak!',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9B2B1A))),
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
          setState(() => _currentQuestionIndex++);
          _startQuestion();
        }
      }
    });
  }

  Future<void> _completeTest() async {
    await _saveCognitiveMetrics();
    widget.onComplete(_score);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveCognitiveMetrics() async {
    try {
      final correctAnswers = _answers.where((a) => a.isCorrect).length;
      final totalQuestions = _answers.length;
      final totalResponseTime =
          _answers.fold<int>(0, (sum, a) => sum + a.responseTime);
      final averageResponseTime = totalResponseTime / totalQuestions;
      final accuracy = correctAnswers / totalQuestions;
      _sessionManager.storeStroopMetrics(
        accuracy: accuracy,
        avgResponseTime: averageResponseTime,
        interferenceScore: 1.0 - accuracy,
      );
    } catch (e) {
      debugPrint('❌ Failed to store Stroop metrics: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showInstructions) return _buildInstructions();
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
                const SizedBox(height: 12),
                _buildProgressBar(),
                const SizedBox(height: 16),
                _buildTimer(),
                const SizedBox(height: 16),
                _buildLabel(),
                const SizedBox(height: 12),
                _buildWordDisplay(),
                const SizedBox(height: 16),
                _buildOptions(),
                const SizedBox(height: 12),
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
                    const Text('Stroop Test',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A0A08))),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          color: Color(0xFF1A0A08), size: 28),
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
                                  curve: Curves.easeInOut),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF9B2B1A),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.psychology,
                                  size: 64, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text('How to Play',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A0A08))),
                          const SizedBox(height: 24),
                          _buildInstructionCard('1', 'Color Word',
                              'Say the INK color, not the word',
                              Icons.palette),
                          const SizedBox(height: 12),
                          _buildInstructionCard('2', 'Color Patch',
                              'Name the color you see', Icons.circle),
                          const SizedBox(height: 12),
                          _buildInstructionCard('3', 'Arrow Direction',
                              'Ignore the text, follow the arrow',
                              Icons.arrow_upward),
                          const SizedBox(height: 12),
                          _buildInstructionCard('4', 'Word Position',
                              'Where is the text on screen?',
                              Icons.vertical_align_top),
                          const SizedBox(height: 12),
                          _buildInstructionCard('5', 'Answer Quickly',
                              'You have 3 seconds per question',
                              Icons.timer),
                          const SizedBox(height: 12),
                          _buildInstructionCard('6', 'Build Streaks',
                              'Consecutive correct = bonus points!',
                              Icons.local_fire_department),
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
                      backgroundColor: const Color(0xFF9B2B1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Start Test',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF9B2B1A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9B2B1A))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0A08))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF666666))),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF9B2B1A), size: 24),
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
            const Text('Stroop Test',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A08))),
            Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF666666))),
          ],
        ),
        Row(
          children: [
            if (_streak > 1)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text('${_streak}x',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
          ],
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
            const Text('Progress',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666))),
            Text(
                '${((_currentQuestionIndex + 1) / _questions.length * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B2B1A))),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          backgroundColor: const Color(0xFFE5D5CC),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B2B1A)),
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
        return Center(
          child: Column(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1 - _progressController.value,
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFFE5D5CC),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timeLeft <= 1
                            ? Colors.red
                            : const Color(0xFF9B2B1A),
                      ),
                    ),
                    Text('$_timeLeft',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _timeLeft <= 1
                                ? Colors.red
                                : const Color(0xFF1A0A08))),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text('sec',
                  style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel() {
    final type = _currentQuestion.type;
    String label;
    Color labelColor;
    switch (type) {
      case StroopQuestionType.classic:
        label = 'COLOR WORD';
        labelColor = const Color(0xFF9B2B1A);
        break;
      case StroopQuestionType.reverse:
        label = 'COLOR PATCH';
        labelColor = const Color(0xFF1E88E5);
        break;
      case StroopQuestionType.spatial:
        label = 'ARROW DIRECTION';
        labelColor = const Color(0xFF8E24AA);
        break;
      case StroopQuestionType.auditory:
        label = 'WORD POSITION';
        labelColor = const Color(0xFF00897B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: labelColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1)),
    );
  }

  Widget _buildWordDisplay() {
    final q = _currentQuestion;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Text(_promptText,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          _buildDisplayContent(q),
        ],
      ),
    );
  }

  Widget _buildDisplayContent(StroopQuestion q) {
    switch (q.type) {
      case StroopQuestionType.classic:
        return Text(q.word,
            style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: q.wordColor,
                letterSpacing: 2));

      case StroopQuestionType.reverse:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: q.wordColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: q.wordColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
        );

      case StroopQuestionType.spatial:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _arrowIcon(q.arrowDirection ?? ArrowDirection.up),
              size: 64,
              color: q.wordColor,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(q.word,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: q.wordColor.withValues(alpha: 0.5),
                      letterSpacing: 1)),
            ),
          ],
        );

      case StroopQuestionType.auditory:
        return SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: _PositionLinesPainter(),
                ),
              ),
              if (q.pitchPosition == PitchPosition.high)
                Positioned(
                  top: 0,
                  child: Text(q.word,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: q.wordColor)),
                )
              else
                Positioned(
                  bottom: 0,
                  child: Text(q.word,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: q.wordColor)),
                ),
            ],
          ),
        );
    }
  }

  IconData _arrowIcon(ArrowDirection dir) {
    switch (dir) {
      case ArrowDirection.up: return Icons.arrow_upward;
      case ArrowDirection.down: return Icons.arrow_downward;
      case ArrowDirection.left: return Icons.arrow_back;
      case ArrowDirection.right: return Icons.arrow_forward;
    }
  }

  Widget _buildOptions() {
    final type = _currentQuestion.type;
    if (type == StroopQuestionType.auditory) {
      return _buildAuditoryOptions();
    }
    return _buildGridOptions();
  }

  Widget _buildGridOptions() {
    final q = _currentQuestion;
    final isSpatial = q.type == StroopQuestionType.spatial;
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: q.options.map((option) {
              final optionColor = isSpatial
                  ? _spatialOptionColor(option)
                  : _colorOptionColor(option);
              return InkWell(
                onTap: _answered ? null : () => _handleAnswer(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: optionColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSpatial)
                        Icon(_spatialOptionIcon(option),
                            color: optionColor, size: 26)
                      else
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                              color: optionColor, shape: BoxShape.circle),
                        ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A0A08),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAuditoryOptions() {
    return Expanded(
      child: Center(
        child: Row(
          children: _currentQuestion.options.map((option) {
            final isHigh = option == 'High';
            final color = isHigh
                ? const Color(0xFF00897B)
                : const Color(0xFFE53935);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    left: isHigh ? 0 : 6, right: isHigh ? 6 : 0),
                child: InkWell(
                  onTap: _answered ? null : () => _handleAnswer(option),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isHigh
                              ? Icons.vertical_align_top
                              : Icons.vertical_align_bottom,
                          color: color, size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(option,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _colorOptionColor(String option) {
    switch (option) {
      case 'Red': return const Color(0xFFF44336);
      case 'Blue': return const Color(0xFF2196F3);
      case 'Green': return const Color(0xFF4CAF50);
      case 'Yellow': return const Color(0xFFFFEB3B);
      default: return const Color(0xFF9B2B1A);
    }
  }

  Color _spatialOptionColor(String option) {
    switch (option) {
      case 'Up': return const Color(0xFF4CAF50);
      case 'Down': return const Color(0xFFF44336);
      case 'Left': return const Color(0xFF2196F3);
      case 'Right': return const Color(0xFFFF9800);
      default: return const Color(0xFF9B2B1A);
    }
  }

  IconData _spatialOptionIcon(String option) {
    switch (option) {
      case 'Up': return Icons.arrow_upward;
      case 'Down': return Icons.arrow_downward;
      case 'Left': return Icons.arrow_back;
      case 'Right': return Icons.arrow_forward;
      default: return Icons.help_outline;
    }
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF9B2B1A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Color(0xFF9B2B1A), size: 22),
          const SizedBox(width: 6),
          const Text('Score: ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A0A08))),
          Text('$_score',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9B2B1A))),
        ],
      ),
    );
  }
}

class _PositionLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0D5CC)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashGap = 4.0;

    void drawDashedLine(double y) {
      double x = 20;
      while (x < size.width - 20) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
        x += dashWidth + dashGap;
      }
    }

    final topLine = size.height * 0.15;
    final bottomLine = size.height * 0.85;
    drawDashedLine(topLine);
    drawDashedLine(bottomLine);

    final labelStyle = TextStyle(
      color: const Color(0xFFB0A59A),
      fontSize: 10,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(text: '▲ HIGH', style: labelStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 60, topLine - 14));

    textPainter.text = TextSpan(text: '▼ LOW', style: labelStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 56, bottomLine + 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
