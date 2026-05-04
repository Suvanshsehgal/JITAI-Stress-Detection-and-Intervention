import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_stage.dart';
import '../widget/custom_button.dart';
import '../services/session_manager.dart';
import '../services/sensor_capture_service.dart';
import '../services/stress_score_service.dart';
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
  final SensorCaptureService _sensorService = SensorCaptureService();

  bool _isInitializing = false;
  bool _isRecording = false;
  Timer? _silentCaptureTimer;

  // Part 4: Baseline tracking
  final List<String> _completedSessionIds = [];
  bool _isBaselineWeek = true; // default true if not set

  @override
  void initState() {
    super.initState();
    _loadBaselinePrefs();
  }

  Future<void> _loadBaselinePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isBaselineWeek = prefs.getBool('is_baseline_week') ?? true;
      });
      debugPrint('📊 Baseline week: $_isBaselineWeek');
    } catch (e) {
      debugPrint('❌ Failed to load baseline prefs: $e');
    }
  }

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
    debugPrint('🔍 Starting test - checking auth state...');

    if (!_sessionManager.hasActiveSession) {
      setState(() => _isInitializing = true);
      final success = await _sessionManager.startSession();
      setState(() => _isInitializing = false);

      if (!success) {
        if (mounted) {
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
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
            ),
          );
        }
        return;
      }
    }

    // Phase 1: pre_test sensor capture — only on first start, not on continuation
    if (_progress.completedStages.isEmpty) {
      await _runPreTestCapture();
    } else {
      _navigateToStage(_progress.currentStage);
    }
  }

  /// Capture pre-test baseline silently in the background (no UI indicator)
  Future<void> _runPreTestCapture() async {
    setState(() => _isRecording = true);
    _sensorService.startCapture('pre_test');

    // Wait 30s silently — user sees the normal test map UI
    await Future.delayed(const Duration(seconds: 30));

    if (!mounted) return;

    final result = await _sensorService.stopCapture();
    setState(() => _isRecording = false);

    // Save pre_test sensor data
    final sessionId = _sessionManager.sessionId;
    if (sessionId != null) {
      await _sensorService.saveToDatabase(
        result: result,
        sessionId: sessionId,
        phase: 'pre_test',
        isBaselineSession: _isBaselineWeek,
      );
    }

    if (!mounted) return;
    _navigateToStage(_progress.currentStage);
  }

  void _navigateToStage(TestStage stage) async {
    late Widget screen;

    switch (stage) {
      case TestStage.ppgPre:
        screen = PpgTestScreen(
          isPre: true,
          onComplete: (bpm) => _onStageComplete(stage, {'bpm': bpm}),
          sensorService: _sensorService,
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
          sensorService: _sensorService,
        );
        break;
      case TestStage.speedAnswerTest:
        screen = SpeedAnswerTestScreen(
          onComplete: (score) => _onStageComplete(stage, {'score': score}),
          sensorService: _sensorService,
        );
        break;
      case TestStage.patternMemoryTest:
        screen = PatternMemoryTestScreen(
          onComplete: (score) => _onStageComplete(stage, {'score': score}),
          sensorService: _sensorService,
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
          sensorService: _sensorService,
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

    // After any screen pops back, check if we've reached completion
    if (mounted && _progress.currentStage == TestStage.completed) {
      _showCompletionDialog();
    }
  }

  void _onStageComplete(TestStage stage, Map<String, dynamic> result) {
    setState(() {
      _progress.completedStages[stage] = true;
      _progress.results[stage.name] = result;

      final currentIndex = TestStage.values.indexOf(stage);
      if (currentIndex < TestStage.values.length - 1) {
        _progress = _progress.copyWith(
          currentStage: TestStage.values[currentIndex + 1],
        );
      } else {
        _progress = _progress.copyWith(currentStage: TestStage.completed);
      }
    });

    // Collect session ID when the final stage completes
    if (_progress.currentStage == TestStage.completed) {
      final sessionId = _sessionManager.sessionId;
      if (sessionId != null && !_completedSessionIds.contains(sessionId)) {
        _completedSessionIds.add(sessionId);
        debugPrint('📊 Session collected for baseline: $sessionId (total: ${_completedSessionIds.length})');
      }
      // Do NOT call _showCompletionDialog here.
      // The ppgPost screen handles its own sensor save before calling onComplete,
      // which pops back to TestMapScreen. _navigateToStage then handles completion.
    }
  }

  Future<void> _showCompletionDialog() async {
    // Capture session ID first — endSession will clear it
    final completedSessionId = _sessionManager.sessionId;
    debugPrint('📊 Completing session: $completedSessionId');

    // STEP 1: Compute stress score BEFORE ending session
    // (all data — sensor, cognitive, PPG, WHO-5 — is already saved at this point)
    if (completedSessionId != null) {
      try {
        debugPrint('📊 Computing stress score...');
        final stressResult =
            await StressScoreService().computeAndSave(completedSessionId);
        if (stressResult != null) {
          debugPrint('✅ Stress score: ${stressResult.stressScore.toStringAsFixed(3)} '
              '(label: ${stressResult.stressLabelBinary}, '
              'confidence: ${stressResult.labelConfidence.toStringAsFixed(3)})');
        } else {
          debugPrint('⚠️ Stress score returned null');
        }
      } catch (e) {
        debugPrint('❌ Stress score computation failed: $e');
      }
    } else {
      debugPrint('❌ Cannot compute stress score: session ID is null');
    }

    // STEP 2: End session (marks end_time, clears session ID)
    await _sessionManager.endSession();

    // STEP 3: Baseline trigger — after 5th session during baseline week
    if (_isBaselineWeek && _completedSessionIds.length >= 5) {
      try {
        debugPrint('📊 Triggering baseline computation after 5th session...');
        await _sensorService.computeAndSaveBaseline(_completedSessionIds);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_baseline_week', false);
        setState(() => _isBaselineWeek = false);
        debugPrint('✅ Baseline week complete. Flag set to false.');
      } catch (e) {
        debugPrint('❌ Baseline computation failed: $e');
      }
    }

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
          style: TextStyle(color: Color(0xFF1A0A08), fontSize: 16),
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
  void dispose() {
    _silentCaptureTimer?.cancel();
    super.dispose();
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
                // Recording banner — shown only while sensor capture is active
                if (_isRecording) _buildRecordingBanner(),

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
                      icon: const Icon(Icons.close,
                          color: Color(0xFF1A0A08), size: 28),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline,
                          color: Color(0xFF9B2B1A), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF666666)),
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

                Expanded(
                  child: ListView.builder(
                    itemCount: _testStages.length,
                    itemBuilder: (context, index) {
                      final stageData = _testStages[index];
                      final stage = stageData['stage'] as TestStage;
                      final isCompleted =
                          _progress.completedStages[stage] ?? false;
                      final isCurrent = _progress.currentStage == stage;
                      final isLocked = !isCompleted && !isCurrent;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFF9B2B1A)
                                        : isCurrent
                                            ? const Color(0xFF9B2B1A)
                                                .withValues(alpha: 0.2)
                                            : const Color(0xFFE5D5CC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 24)
                                        : isLocked
                                            ? const Icon(Icons.lock,
                                                color: Color(0xFF999999),
                                                size: 24)
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

                // Bottom area: initializing / start button
                if (_isInitializing)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomButton(
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

  Widget _buildRecordingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Pulsing red dot
          _PulsingDot(),
          const SizedBox(width: 10),
          const Text(
            'Recording sensor data...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing red dot for the recording banner
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFE53935),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
