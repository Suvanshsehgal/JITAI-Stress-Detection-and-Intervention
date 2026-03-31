import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/ppg/camera_preview_widget.dart';
import '../widget/ppg/camera_circle_widget.dart';
import '../widget/ppg/bpm_circle.dart';
import '../widget/ppg/ppg_waveform.dart';
import '../widget/ppg/progress_section.dart';
import '../widget/custom_button.dart';
import '../services/camera_service.dart';

class PpgScreen extends StatefulWidget {
  const PpgScreen({super.key});

  @override
  State<PpgScreen> createState() => _PpgScreenState();
}

class _PpgScreenState extends State<PpgScreen> with TickerProviderStateMixin {
  late AnimationController _heartBeatController;
  late AnimationController _rippleController;
  late AnimationController _waveController;
  late AnimationController _progressController;

  late Animation<double> _heartBeatAnimation;
  late Animation<double> _rippleAnimation1;
  late Animation<double> _rippleAnimation2;

  final CameraService _cameraService = CameraService();
  bool _isScanning = false;
  int _bpm = 72;
  bool _measurementComplete = false;

  @override
  void initState() {
    super.initState();

    // Heart beat animation (833ms per beat for 72 BPM)
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 833),
      vsync: this,
    );

    _heartBeatAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _heartBeatController,
        curve: Curves.easeInOut,
      ),
    );

    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 833),
      vsync: this,
    );

    _rippleAnimation1 = Tween<double>(begin: 0.5, end: 1.1).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );

    _rippleAnimation2 = Tween<double>(begin: 0.5, end: 1.1).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Wave animation (continuous scroll)
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Progress animation (30 seconds)
    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Listen to progress completion
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onMeasurementComplete();
      }
    });
  }

  void _onMeasurementComplete() {
    setState(() {
      _measurementComplete = true;
      _bpm = 88; // Set final BPM to 88
    });
    
    // Stop all animations
    _heartBeatController.stop();
    _rippleController.stop();
    _waveController.stop();
  }

  Future<void> _startBpmCheck() async {
    setState(() {
      _isScanning = true;
      _measurementComplete = false;
      _bpm = 88;
    });

    // Initialize camera
    final success = await _cameraService.initialize();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize camera')),
        );
        setState(() {
          _isScanning = false;
        });
      }
      return;
    }

    // Turn on flash
    await _cameraService.turnOnFlash();

    // Start all animations
    _heartBeatController.repeat();
    _rippleController.repeat();
    _waveController.repeat();
    _progressController.forward();

    setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _heartBeatController.dispose();
    _rippleController.dispose();
    _waveController.dispose();
    _progressController.dispose();
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
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          color: const Color(0xFF1A0A08),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Lorem Ipsum',
                          style: TextStyle(
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
                ),

                const SizedBox(height: 32),

                // Camera circle at top (only show when scanning)
                if (_isScanning) ...[
                  CameraCircleWidget(
                    cameraController: _cameraService.controller,
                  ),
                  const SizedBox(height: 24),
                ],

                // Camera preview or BPM Circle
                if (!_isScanning)
                  Column(
                    children: [
                      const CameraPreviewWidget(),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Check BPM',
                        onPressed: _startBpmCheck,
                      ),
                    ],
                  )
                else
                  BpmCircle(
                    bpm: _bpm,
                    heartBeatAnimation: _heartBeatAnimation,
                    rippleAnimation1: _rippleAnimation1,
                    rippleAnimation2: _rippleAnimation2,
                    isAnimating: !_measurementComplete,
                  ),

                const SizedBox(height: 40),

                // PPG Waveform (only show when scanning and not complete)
                if (_isScanning && !_measurementComplete) ...[
                  PpgWaveform(waveAnimation: _waveController),
                  const Spacer(),
                  ProgressSection(progressAnimation: _progressController),
                  const SizedBox(height: 20),
                ] else if (_isScanning && _measurementComplete) ...[
                  const Spacer(),
                  CustomButton(
                    text: 'Continue',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  const Spacer(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
