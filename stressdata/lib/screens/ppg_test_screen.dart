import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import '../services/ppg_service.dart';
import '../services/session_manager.dart';
import '../services/database_service.dart';
import '../services/sensor_capture_service.dart';
import '../config/supabase_config.dart';
import '../models/ppg_data.dart';
import '../widget/custom_button.dart';
import '../widget/ppg/ppg_waveform_painter.dart';
import '../core/theme/colors.dart';
import 'ppg_instruction_screen.dart';

class PpgTestScreen extends StatefulWidget {
  final bool isPre;
  final Function(int bpm) onComplete;
  final SensorCaptureService sensorService;

  const PpgTestScreen({
    super.key,
    required this.isPre,
    required this.onComplete,
    required this.sensorService,
  });

  @override
  State<PpgTestScreen> createState() => _PpgTestScreenState();
}

class _PpgTestScreenState extends State<PpgTestScreen>
    with TickerProviderStateMixin {
  final PPGService _ppgService = PPGService();
  final SessionManager _sessionManager = SessionManager();
  final DatabaseService _dbService = DatabaseService();
  
  // State
  PPGState _currentState = PPGState.initializing;
  int _currentBPM = 0;
  double _confidence = 0.0;
  SignalQuality _signalQuality = SignalQuality.noSignal;
  List<double> _waveformData = [];
  String _statusMessage = 'Initializing...';
  bool _isRecording = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  // Subscriptions
  StreamSubscription? _bpmSubscription;
  StreamSubscription? _confidenceSubscription;
  StreamSubscription? _qualitySubscription;
  StreamSubscription? _waveformSubscription;
  StreamSubscription? _stateSubscription;
  
  // Measurement timer
  Timer? _measurementTimer;
  int _secondsElapsed = 0;
  final int _measurementDuration = 30; // 30 seconds

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePPG();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  Future<void> _initializePPG() async {
    final success = await _ppgService.initialize();
    
    if (!success) {
      if (mounted) {
        setState(() {
          _currentState = PPGState.error;
          _statusMessage = 'Failed to initialize camera';
        });
        _showErrorDialog();
      }
      return;
    }

    // Subscribe to streams
    _bpmSubscription = _ppgService.bpmStream.listen((bpm) {
      if (mounted) {
        setState(() {
          _currentBPM = bpm;
        });
        _triggerPulse();
      }
    });

    _confidenceSubscription = _ppgService.confidenceStream.listen((confidence) {
      if (mounted) {
        setState(() {
          _confidence = confidence;
        });
      }
    });

    _qualitySubscription = _ppgService.qualityStream.listen((quality) {
      if (mounted) {
        setState(() {
          _signalQuality = quality;
          _updateStatusMessage();
        });
      }
    });

    _waveformSubscription = _ppgService.waveformStream.listen((waveform) {
      if (mounted) {
        setState(() {
          _waveformData = waveform;
        });
      }
    });

    _stateSubscription = _ppgService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
          _updateStatusMessage();
        });
      }
    });

    // Start measurement timer
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
        
        if (_secondsElapsed >= _measurementDuration) {
          _completeMeasurement();
        }
      }
    });
  }

  void _triggerPulse() {
    if (_pulseController.isAnimating) return;
    _pulseController.forward().then((_) => _pulseController.reverse());
  }

  void _updateStatusMessage() {
    switch (_currentState) {
      case PPGState.initializing:
        _statusMessage = 'Initializing camera...';
        break;
      case PPGState.warmingUp:
        _statusMessage = 'Warming up... Keep finger steady';
        break;
      case PPGState.measuring:
        if (_signalQuality == SignalQuality.excellent || 
            _signalQuality == SignalQuality.good) {
          _statusMessage = 'Measuring... Keep finger steady';
        } else if (_signalQuality == SignalQuality.fair) {
          _statusMessage = 'Fair signal - Try to stay still';
        } else {
          _statusMessage = 'Poor signal - Adjust finger position';
        }
        break;
      case PPGState.complete:
        _statusMessage = 'Measurement complete!';
        break;
      case PPGState.error:
        _statusMessage = 'Error occurred';
        break;
    }
  }

  void _completeMeasurement() {
    _measurementTimer?.cancel();
    
    // Check if we have a valid BPM reading
    final hasValidReading = _currentBPM > 0 && _currentBPM >= 40 && _currentBPM <= 200;
    
    if (hasValidReading) {
      // Valid reading - show complete state
      setState(() {
        _currentState = PPGState.complete;
        _updateStatusMessage();
      });
      debugPrint('✅ PPG: Measurement complete with BPM: $_currentBPM');
    } else {
      // No valid reading - show retry dialog
      debugPrint('⚠️ PPG: No valid reading after 30s. BPM: $_currentBPM');
      _showRetryDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Camera Error',
          style: TextStyle(
            color: Color(0xFF1A0A08),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Unable to access camera or flash. Please check permissions and try again.',
          style: TextStyle(color: Color(0xFF1A0A08)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
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

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Measurement Incomplete',
          style: TextStyle(
            color: Color(0xFF1A0A08),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Unable to get a reliable reading. Please ensure your finger covers the camera completely and try again.',
          style: TextStyle(color: Color(0xFF1A0A08)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryMeasurement();
            },
            child: const Text(
              'Retry',
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

  void _retryMeasurement() {
    setState(() {
      _secondsElapsed = 0;
      _currentBPM = 0;
      _confidence = 0.0;
      _signalQuality = SignalQuality.noSignal;
      _waveformData = [];
    });
    
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
        
        if (_secondsElapsed >= _measurementDuration) {
          _completeMeasurement();
        }
      }
    });
  }

  Future<void> _handleComplete() async {
    final result = _ppgService.getResult();
    int bpm = 72; // default
    
    if (result != null) {
      bpm = result.bpm;
    } else if (_currentBPM > 0) {
      bpm = _currentBPM;
    }

    // Save PPG data first
    await _saveToDatabase(bpm);

    // Post-test PPG: run post_test sensor capture + recovery
    if (!widget.isPre) {
      await _runPostTestAndRecovery(bpm);
    } else {
      widget.onComplete(bpm);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _runPostTestAndRecovery(int bpm) async {
    if (!mounted) return;

    // post_test — 30s silent sensor capture with recording banner
    if (mounted) setState(() => _isRecording = true);
    widget.sensorService.startCapture('post_test');
    await Future.delayed(const Duration(seconds: 30));
    final postResult = await widget.sensorService.stopCapture();
    if (mounted) setState(() => _isRecording = false);

    if (!mounted) return;

    // Save post_test sensor data silently
    final sessionId = _sessionManager.sessionId;
    if (sessionId != null) {
      try {
        await widget.sensorService.saveToDatabase(
          result: postResult,
          sessionId: sessionId,
          phase: 'post_test',
          ppgBpm: bpm.toDouble(),
          hrvEstimate: 50.0, // placeholder
        );
      } catch (e) {
        debugPrint('❌ post_test sensor save error: $e');
      }
    }

    widget.onComplete(bpm);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveToDatabase(int bpm) async {
    try {
      final sessionId = _sessionManager.sessionId;
      final userId = _sessionManager.userId;

      if (sessionId == null || userId == null) {
        throw Exception('No active session or user');
      }

      // Get PPG result with quality metrics
      final result = _ppgService.getResult();
      final heartRate = bpm.toDouble();
      final hrv = result?.hrv?.rmssd ?? 50.0; // Use actual HRV if available
      final stressIndex = _calculateStressIndex(bpm);
      
      // Calculate signal quality score (0.0 - 1.0)
      final signalQuality = _confidence / 100.0; // Convert confidence percentage to 0-1 scale

      await _dbService.insertPPGResults(
        sessionId: sessionId,
        userId: userId,
        heartRate: heartRate,
        hrv: hrv,
        stressIndex: stressIndex,
      );

      // CRITICAL: Save PPG signal quality to physiological_metrics
      // This is required for stress score calculation
      await SupabaseConfig.client
          .from('physiological_metrics')
          .update({'ppg_signal_quality': signalQuality})
          .eq('session_id', sessionId);

      debugPrint('✅ PPG data saved successfully (isPre: ${widget.isPre})');
      debugPrint('   BPM: $bpm, HRV: $hrv, Quality: ${signalQuality.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('❌ Failed to save PPG data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save heart rate data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateStressIndex(int bpm) {
    // Simple stress index based on heart rate
    // Normal resting: 60-100 bpm
    if (bpm < 60) return 0.3; // Low
    if (bpm <= 80) return 0.5; // Normal
    if (bpm <= 100) return 0.7; // Slightly elevated
    return 0.9; // High
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _measurementTimer?.cancel();
    _bpmSubscription?.cancel();
    _confidenceSubscription?.cancel();
    _qualitySubscription?.cancel();
    _waveformSubscription?.cancel();
    _stateSubscription?.cancel();
    _ppgService.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;
                
                // Calculate responsive sizes
                final cameraSize = screenHeight > 600 ? 250.0 : 200.0;
                final padding = screenHeight > 600 ? 20.0 : 16.0;
                final spacing = screenHeight > 600 ? 32.0 : 20.0;
                
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            // Recording banner — shown only during post_test sensor capture
                            if (_isRecording) _buildRecordingBanner(),

                            _buildHeader(),
                            SizedBox(height: spacing),
                            _buildProgressIndicator(),
                            SizedBox(height: spacing),
                            
                            // Camera view circle with heart rate in center
                            _buildCameraViewCircle(size: cameraSize),
                            
                            SizedBox(height: spacing),
                            _buildWaveform(),
                            SizedBox(height: spacing / 2),
                            _buildStatusMessage(),
                            const Spacer(),
                            if (_currentState == PPGState.complete)
                              CustomButton(
                                text: 'Continue',
                                onPressed: _handleComplete,
                              )
                            else
                              Column(
                                children: [
                                  _buildInstructions(),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      // Show instruction screen again
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PPGInstructionScreen(
                                            onContinue: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Need visual guide?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary.withValues(alpha: 0.7),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: padding),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.favorite,
              color: Color(0xFF9B2B1A),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              widget.isPre ? 'Pre-Test Heart Rate' : 'Post-Test Heart Rate',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0A08),
              ),
            ),
          ],
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
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _secondsElapsed / _measurementDuration;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              '${_secondsElapsed}s / ${_measurementDuration}s',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B2B1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFE5D5CC),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B2B1A)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildCameraViewCircle({double size = 250}) {
    final heartRateSize = size * 0.48; // 48% of camera size
    final fontSize = size * 0.192; // 48% of 40% of size
    
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera preview circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(
                color: const Color(0xFF9B2B1A),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: _buildCameraPreview(),
            ),
          ),
          
          // Heart rate display overlay in center
          Positioned(
            child: Container(
              width: heartRateSize,
              height: heartRateSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.7),
                border: Border.all(
                  color: const Color(0xFF9B2B1A),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentBPM > 0)
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: _currentBPM),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Text(
                          '$value',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  else if (_currentState == PPGState.warmingUp)
                    Icon(
                      Icons.favorite,
                      size: fontSize,
                      color: Colors.white,
                    )
                  else
                    SizedBox(
                      width: fontSize * 0.5,
                      height: fontSize * 0.5,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _currentBPM > 0
                        ? 'BPM'
                        : _currentState == PPGState.warmingUp
                            ? 'Warming Up'
                            : 'Initializing',
                    style: TextStyle(
                      fontSize: fontSize * 0.3,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentBPM > 0 && _confidence > 0) ...[
                    const SizedBox(height: 4),
                    _buildConfidenceIndicator(),
                  ],
                ],
              ),
            ),
          ),
          
          // Finger placement guide
          Positioned(
            bottom: size * 0.08,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.064,
                vertical: size * 0.032,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: size * 0.064,
                  ),
                  SizedBox(width: size * 0.032),
                  Text(
                    'Cover camera & flash',
                    style: TextStyle(
                      fontSize: size * 0.048,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraPreview() {
    if (_ppgService.cameraController != null && 
        _ppgService.cameraController!.value.isInitialized) {
      return CameraPreview(_ppgService.cameraController!);
    } else {
      // Show placeholder while camera is initializing
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF333333),
              Colors.black,
            ],
            stops: [0.3, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _currentState == PPGState.initializing
                    ? 'Initializing camera...'
                    : 'Camera warming up...',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildConfidenceIndicator() {
    Color confidenceColor;
    if (_confidence >= 80) {
      confidenceColor = Colors.green;
    } else if (_confidence >= 60) {
      confidenceColor = Colors.lightGreen;
    } else if (_confidence >= 40) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '${_confidence.toInt()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _waveformData.isNotEmpty
            ? CustomPaint(
                painter: PPGWaveformPainter(
                  waveformData: _waveformData,
                  waveColor: const Color(0xFF9B2B1A),
                ),
                size: Size.infinite,
              )
            : const Center(
                child: Text(
                  'Waiting for signal...',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    IconData icon;
    Color iconColor;

    switch (_signalQuality) {
      case SignalQuality.excellent:
      case SignalQuality.good:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case SignalQuality.fair:
        icon = Icons.warning;
        iconColor = Colors.orange;
        break;
      case SignalQuality.poor:
      case SignalQuality.noSignal:
        icon = Icons.error;
        iconColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Guide',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInstructionStep('• Cover camera & flash with fingertip'),
          _buildInstructionStep('• Apply light pressure'),
          _buildInstructionStep('• Keep finger still for 30s'),
          const SizedBox(height: 4),
          Text(
            'Tap "Need visual guide?" for detailed instructions',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3.0),
            child: Icon(
              Icons.circle,
              size: 5,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
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
