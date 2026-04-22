import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/ppg_service.dart';
import '../models/ppg_data.dart';
import '../widget/custom_button.dart';
import '../widget/ppg/ppg_waveform_painter.dart';
import '../core/theme/colors.dart';

class PpgTestScreen extends StatefulWidget {
  final bool isPre;
  final Function(int bpm) onComplete;

  const PpgTestScreen({
    super.key,
    required this.isPre,
    required this.onComplete,
  });

  @override
  State<PpgTestScreen> createState() => _PpgTestScreenState();
}

class _PpgTestScreenState extends State<PpgTestScreen>
    with TickerProviderStateMixin {
  final PPGService _ppgService = PPGService();
  
  // State
  PPGState _currentState = PPGState.initializing;
  int _currentBPM = 0;
  double _confidence = 0.0;
  SignalQuality _signalQuality = SignalQuality.noSignal;
  List<double> _waveformData = [];
  String _statusMessage = 'Initializing...';
  
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
    
    final result = _ppgService.getResult();
    
    if (result != null && result.isReliable) {
      setState(() {
        _currentState = PPGState.complete;
        _updateStatusMessage();
      });
    } else {
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

  void _handleComplete() {
    final result = _ppgService.getResult();
    if (result != null) {
      widget.onComplete(result.bpm);
    } else {
      widget.onComplete(_currentBPM > 0 ? _currentBPM : 72);
    }
    Navigator.pop(context);
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildProgressIndicator(),
                  const SizedBox(height: 32),
                  _buildHeartRateDisplay(),
                  const SizedBox(height: 32),
                  _buildWaveform(),
                  const SizedBox(height: 24),
                  _buildStatusMessage(),
                  const Spacer(),
                  if (_currentState == PPGState.complete)
                    CustomButton(
                      text: 'Continue',
                      onPressed: _handleComplete,
                    )
                  else
                    _buildInstructions(),
                  const SizedBox(height: 20),
                ],
              ),
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

  Widget _buildHeartRateDisplay() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B2B1A).withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentState == PPGState.measuring && _currentBPM > 0)
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: _currentBPM),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9B2B1A),
                    ),
                  );
                },
              )
            else if (_currentState == PPGState.warmingUp)
              const Icon(
                Icons.favorite,
                size: 64,
                color: Color(0xFF9B2B1A),
              )
            else
              const CircularProgressIndicator(
                color: Color(0xFF9B2B1A),
              ),
            const SizedBox(height: 8),
            Text(
              _currentState == PPGState.measuring && _currentBPM > 0
                  ? 'BPM'
                  : _currentState == PPGState.warmingUp
                      ? 'Warming Up'
                      : 'Initializing',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            if (_currentState == PPGState.measuring && _confidence > 0) ...[
              const SizedBox(height: 8),
              _buildConfidenceIndicator(),
            ],
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            size: 16,
            color: confidenceColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${_confidence.toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: confidenceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 120,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Place your finger firmly on the back camera and flash. Keep it steady for ${_measurementDuration} seconds.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
