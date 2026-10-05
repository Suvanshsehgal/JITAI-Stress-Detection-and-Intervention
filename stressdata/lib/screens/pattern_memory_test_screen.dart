import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../models/pattern_memory_model.dart';
import '../services/session_manager.dart';
import '../services/sensor_capture_service.dart';

const _displayDuration = 3;
const _inputDuration = 5;

const _shapeColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFD81B60),
  Color(0xFF6D4C41),
];

const _shapes = PatternShape.values;

class _CellDisplay {
  final PatternShape shape;
  final Color color;
  _CellDisplay({required this.shape, required this.color});
}

class PatternMemoryTestScreen extends StatefulWidget {
  final Function(int score) onComplete;
  final SensorCaptureService sensorService;

  const PatternMemoryTestScreen({
    super.key,
    required this.onComplete,
    required this.sensorService,
  });

  @override
  State<PatternMemoryTestScreen> createState() =>
      _PatternMemoryTestScreenState();
}

class _PatternMemoryTestScreenState extends State<PatternMemoryTestScreen>
    with TickerProviderStateMixin {
  late final List<PatternQuestion> _questions;
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
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  int _secondsRemaining = 0;
  Timer? _countdownTimer;
  Timer? _phaseTimeout;
  Map<int, _CellDisplay> _cellDisplays = {};

  PatternQuestion get _currentQuestion => _questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == _questions.length - 1;

  @override
  void initState() {
    super.initState();
    final pool = List<PatternQuestion>.from(patternQuestions)..shuffle(Random());
    _questions = pool.take(10).toList();

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
    setState(() => _showInstructions = false);
    _startQuestion();
  }

  void _generateCellDisplays() {
    final displays = <int, _CellDisplay>{};
    final random = Random();
    final colorPool = List<Color>.from(_shapeColors)..shuffle(random);
    final shapePool = List<PatternShape>.from(_shapes)..shuffle(random);

    for (final cellIndex in _currentQuestion.pattern) {
      final color = colorPool[_currentQuestion.pattern.indexOf(cellIndex) % colorPool.length];
      final shape = shapePool[_currentQuestion.pattern.indexOf(cellIndex) % shapePool.length];
      displays[cellIndex] = _CellDisplay(color: color, shape: shape);
    }

    for (int i = 0; i < _currentQuestion.gridSize; i++) {
      if (!displays.containsKey(i)) {
        displays[i] = _CellDisplay(
          color: Colors.grey,
          shape: _shapes[random.nextInt(_shapes.length)],
        );
      }
    }

    _cellDisplays = displays;
  }

  void _startQuestion() {
    _generateCellDisplays();
    _questionStartTime = DateTime.now();
    _secondsRemaining = _displayDuration;
    _selectedCells = [];

    setState(() {
      _showingPattern = true;
      _userTurn = false;
    });

    _fadeController.forward(from: 0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      }
    });

    _phaseTimeout = Timer(Duration(seconds: _displayDuration), () {
      if (mounted) {
        _countdownTimer?.cancel();
        _startInputPhase();
      }
    });
  }

  void _startInputPhase() {
    _secondsRemaining = _inputDuration;

    setState(() {
      _showingPattern = false;
      _userTurn = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      }
    });

    _phaseTimeout = Timer(Duration(seconds: _inputDuration), () {
      if (mounted) {
        _countdownTimer?.cancel();
        _checkAnswer();
      }
    });
  }

  void _handleCellTap(int index) {
    if (!_userTurn || _selectedCells.contains(index)) return;

    setState(() => _selectedCells.add(index));

    if (_selectedCells.length == _currentQuestion.pattern.length) {
      _phaseTimeout?.cancel();
      _countdownTimer?.cancel();
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
              if (_cellDisplays.containsKey(_currentQuestion.pattern.isNotEmpty ? _currentQuestion.pattern.first : -1) && !isCorrect) ...[
                const SizedBox(height: 12),
                _buildPatternPreview(),
              ],
              if (_streak > 1 && isCorrect) ...[
                const SizedBox(height: 8),
                Text(
                  '${_streak}x Streak!',
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

    Future.delayed(const Duration(milliseconds: 1200), () {
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

  Widget _buildPatternPreview() {
    final count = min(_currentQuestion.pattern.length, 6);
    final cells = _currentQuestion.pattern.take(count).toList();
    return Column(
      children: [
        const Text('Correct cells:',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: cells.map((i) {
            final d = _cellDisplays[i];
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: d?.color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: d?.color ?? Colors.grey, width: 2),
              ),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CustomPaint(
                    painter: _ShapePainter(
                      shape: d?.shape ?? PatternShape.circle,
                      color: d?.color ?? Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _completeTest() async {
    await _saveToDatabase();
    widget.onComplete(_score);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      final correctAnswers = _answers.where((a) => a.isCorrect).length;
      final totalQuestions = _answers.length;
      final accuracy = correctAnswers / totalQuestions;
      final maxLevel = _currentQuestionIndex + 1;

      _sessionManager.storeMemoryMetrics(
        maxLevel: maxLevel,
        accuracy: accuracy,
      );

      debugPrint('Pattern Memory metrics stored in SessionManager');
      await _sessionManager.saveCognitiveMetrics();
    } catch (e) {
      debugPrint('Failed to store/save Pattern Memory metrics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save test metrics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phaseTimeout?.cancel();
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
                const SizedBox(height: 20),
                _buildTimerBar(),
                const SizedBox(height: 16),
                _buildStatusIndicator(),
                const SizedBox(height: 20),
                _buildGrid(),
                const SizedBox(height: 20),
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
                                color: Color(0xFF8E24AA),
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
                            'Memorize the shapes, colors, and positions ($_displayDuration sec)',
                            Icons.visibility,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionCard(
                            '2',
                            'Recall & Tap',
                            'Tap the same cells you saw ($_inputDuration sec)',
                            Icons.touch_app,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionCard(
                            '3',
                            'Shapes & Colors',
                            'Each cell has a unique shape and color to remember',
                            Icons.palette,
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
                                  'Shape Legend:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A0A08),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: PatternShape.values.map((s) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CustomPaint(
                                            painter: _ShapePainter(
                                              shape: s,
                                              color: const Color(0xFF4B3425),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
                      backgroundColor: const Color(0xFF8E24AA),
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
              color: const Color(0xFF8E24AA).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E24AA),
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
          Icon(icon, color: const Color(0xFF8E24AA), size: 28),
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
              'Level ${_currentQuestionIndex + 1}/${_questions.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (_streak > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
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
              '${((_currentQuestionIndex + 1) / _questions.length * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E24AA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          backgroundColor: const Color(0xFFE5D5CC),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E24AA)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    final total = _showingPattern ? _displayDuration : _inputDuration;
    final remaining = _secondsRemaining;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _showingPattern ? 'Memorize' : 'Recall',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              '${remaining}s',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: remaining <= 2 ? Colors.red : const Color(0xFF8E24AA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: remaining / total),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, _) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFE5D5CC),
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining <= 2 ? Colors.red : const Color(0xFF8E24AA),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _showingPattern
            ? const Color(0xFF8E24AA).withValues(alpha: 0.1)
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
                ? const Color(0xFF8E24AA)
                : _userTurn
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF666666),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _showingPattern
                ? 'Watch the Pattern... ${_secondsRemaining}s'
                : _userTurn
                    ? 'Your Turn! ${_selectedCells.length}/${_currentQuestion.pattern.length}  ${_secondsRemaining}s'
                    : 'Get Ready...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _showingPattern
                  ? const Color(0xFF8E24AA)
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

    return Flexible(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: gridSize,
          itemBuilder: (context, index) {
            final isPattern = _currentQuestion.pattern.contains(index);
            final isSelected = _selectedCells.contains(index);
            final cellDisplay = _cellDisplays[index];

            if (_showingPattern) {
              return _buildDisplayCell(index, isPattern, cellDisplay);
            } else {
              return _buildInputCell(index, isPattern, isSelected, cellDisplay);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDisplayCell(int index, bool isPattern, _CellDisplay? display) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isPattern
            ? (display?.color ?? const Color(0xFF4CAF50)).withValues(alpha: 0.25)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPattern
              ? (display?.color ?? const Color(0xFF4CAF50))
              : const Color(0xFFE5D5CC),
          width: isPattern ? 3 : 2,
        ),
        boxShadow: isPattern
            ? [
                BoxShadow(
                  color: (display?.color ?? const Color(0xFF4CAF50))
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: display != null
              ? Opacity(
                  opacity: isPattern ? 1.0 : 0.25,
                  child: CustomPaint(
                    painter: _ShapePainter(
                      shape: display.shape,
                      color: isPattern ? display.color : Colors.grey,
                    ),
                    size: const Size.square(40),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildInputCell(
      int index, bool isPattern, bool isSelected, _CellDisplay? display) {
    return GestureDetector(
      onTap: () => _handleCellTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withValues(alpha: 0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : isPattern
                    ? (display?.color ?? const Color(0xFF4CAF50)).withValues(alpha: 0.4)
                    : const Color(0xFFE5D5CC),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isSelected
              ? const Icon(Icons.check, color: Color(0xFF2196F3), size: 32)
              : display != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Opacity(
                        opacity: 0.35,
                        child: CustomPaint(
                          painter: _ShapePainter(
                            shape: display.shape,
                            color: isPattern ? display.color : Colors.grey,
                          ),
                          size: const Size.square(40),
                        ),
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8E24AA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Color(0xFF8E24AA), size: 24),
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
              color: Color(0xFF8E24AA),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final PatternShape shape;
  final Color color;

  _ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) * 0.4;

    switch (shape) {
      case PatternShape.circle:
        canvas.drawCircle(center, r, paint);
        break;
      case PatternShape.triangle:
        _drawTriangle(canvas, center, r, paint);
        break;
      case PatternShape.diamond:
        _drawDiamond(canvas, center, r, paint);
        break;
      case PatternShape.star:
        _drawStar(canvas, center, r, paint);
        break;
      case PatternShape.hexagon:
        _drawPolygon(canvas, center, r, 6, paint);
        break;
      case PatternShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: r * 1.6,
              height: r * 1.6,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
        break;
    }
  }

  void _drawTriangle(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx - r * 0.866, c.dy + r * 0.5)
      ..lineTo(c.dx + r * 0.866, c.dy + r * 0.5)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawDiamond(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final rad = i.isEven ? r : r * 0.45;
      final x = c.dx + rad * cos(angle);
      final y = c.dy + rad * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawPolygon(Canvas canvas, Offset c, double r, int sides, Paint p) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * 2 * pi / sides;
      final x = c.dx + r * cos(angle);
      final y = c.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
