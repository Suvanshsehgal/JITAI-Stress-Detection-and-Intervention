import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/pattern_memory_model.dart';
import '../services/session_manager.dart';
import '../services/database_service.dart';

class PatternMemoryTestScreen extends StatefulWidget {
  final Function(int score) onComplete;

  const PatternMemoryTestScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<PatternMemoryTestScreen> createState() =>
      _PatternMemoryTestScreenState();
}

class _PatternMemoryTestScreenState extends State<PatternMemoryTestScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final List<PatternAnswer> _answers = [];
  bool _showInstructions = true;
  bool _showingPattern = false;
  bool _userTurn = false;
  int _score = 0;
  int _streak = 0;
  List<int> _selectedCells = [];
  DateTime? _questionStartTime;
  final SessionManager _sessionManager = SessionManager();
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  PatternQuestion get _currentQuestion =>
      patternQuestions[_currentQuestionIndex];
  bool get _isLastQuestion =>
      _currentQuestionIndex == patternQuestions.length - 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
      _showingPattern = true;
      _userTurn = false;
      _selectedCells = [];
      _questionStartTime = DateTime.now();
    });

    _fadeController.forward(from: 0);

    Future.delayed(
        Duration(milliseconds: _currentQuestion.displayDuration), () {
      if (mounted) {
        setState(() {
          _showingPattern = false;
          _userTurn = true;
        });
      }
    });
  }

  void _handleCellTap(int index) {
    if (!_userTurn || _selectedCells.contains(index)) return;

    setState(() {
      _selectedCells.add(index);
    });

    if (_selectedCells.length == _currentQuestion.pattern.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final responseTime =
        DateTime.now().difference(_questionStartTime!).inMilliseconds;
    final isCorrect = _listsEqual(_selectedCells, _currentQuestion.pattern);

    _answers.add(PatternAnswer(
      questionId: _currentQuestion.id,
      selectedPattern: List.from(_selectedCells),
      isCorrect: isCorrect,
      responseTime: responseTime,
    ));

    if (isCorrect) {
      _streak++;
      final patternBonus = _currentQuestion.pattern.length * 5;
      final streakBonus = (_streak > 1) ? (_streak * 10) : 0;
      final speedBonus = responseTime < 5000 ? 15 : 0;
      setState(() {
        _score += 20 + patternBonus + streakBonus + speedBonus;
      });
    } else {
      _streak = 0;
    }

    _showFeedback(isCorrect);
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = List<int>.from(a)..sort();
    final sortedB = List<int>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  void _showFeedback(bool isCorrect) {
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
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'Perfect!' : 'Not Quite!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A08),
                ),
              ),
              if (_streak > 1 && isCorrect) ...[
                const SizedBox(height: 8),
                Text(
                  '🧠 ${_streak}x Streak!',
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

    Future.delayed(const Duration(milliseconds: 1000), () {
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
      final sessionId = _sessionManager.sessionId;
      final userId = _sessionManager.userId;

      if (sessionId == null || userId == null) {
        throw Exception('No active session or user');
      }

      // Calculate metrics
      final correctAnswers = _answers.where((a) => a.isCorrect).length;
      final totalQuestions = _answers.length;
      final totalResponseTime = _answers.fold<int>(
        0,
        (sum, answer) => sum + answer.responseTime,
      );
      final averageResponseTime = totalResponseTime / totalQuestions;

      await _dbService.insertPatternMemoryResults(
        sessionId: sessionId,
        userId: userId,
        score: _score,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        averageResponseTime: averageResponseTime,
      );

      debugPrint('✅ Pattern Memory data saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save Pattern Memory data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save test results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
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
                _buildStatusIndicator(),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: _buildGrid(),
                  ),
                ),
                const SizedBox(height: 32),
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
                      'Pattern Memory',
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
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.grid_on,
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
                            'Watch the Pattern',
                            'Memorize which cells light up',
                            Icons.visibility,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionCard(
                            '2',
                            'Recall & Tap',
                            'Tap the same cells you saw',
                            Icons.touch_app,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionCard(
                            '3',
                            'Get Faster',
                            'Patterns get harder as you progress',
                            Icons.trending_up,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Tip:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A0A08),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Focus on the pattern, not individual cells',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
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
                      backgroundColor: const Color(0xFF4CAF50),
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
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
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
            color: const Color(0xFF4CAF50),
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
              'Pattern Memory',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0A08),
              ),
            ),
            Text(
              'Level ${_currentQuestionIndex + 1}/${patternQuestions.length}',
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
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 20),
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
              '${((_currentQuestionIndex + 1) / patternQuestions.length * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / patternQuestions.length,
          backgroundColor: const Color(0xFFE5D5CC),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _showingPattern
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
            : _userTurn
                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showingPattern
                ? Icons.visibility
                : _userTurn
                    ? Icons.touch_app
                    : Icons.hourglass_empty,
            color: _showingPattern
                ? const Color(0xFF4CAF50)
                : _userTurn
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF666666),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _showingPattern
                ? 'Watch the Pattern...'
                : _userTurn
                    ? 'Your Turn! (${_selectedCells.length}/${_currentQuestion.pattern.length})'
                    : 'Get Ready...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _showingPattern
                  ? const Color(0xFF4CAF50)
                  : _userTurn
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final gridSize = _currentQuestion.gridSize;
    final crossAxisCount = gridSize == 9 ? 3 : 4;

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: gridSize,
        itemBuilder: (context, index) {
          final isPattern = _currentQuestion.pattern.contains(index);
          final isSelected = _selectedCells.contains(index);
          final shouldHighlight = _showingPattern && isPattern;

          return FadeTransition(
            opacity: _fadeController,
            child: GestureDetector(
              onTap: () => _handleCellTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: shouldHighlight
                      ? const Color(0xFF4CAF50)
                      : isSelected
                          ? const Color(0xFF2196F3)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: shouldHighlight
                        ? const Color(0xFF4CAF50)
                        : isSelected
                            ? const Color(0xFF2196F3)
                            : const Color(0xFFE5D5CC),
                    width: 3,
                  ),
                  boxShadow: [
                    if (shouldHighlight || isSelected)
                      BoxShadow(
                        color: (shouldHighlight
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2196F3))
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.stars,
            color: Color(0xFF4CAF50),
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
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
