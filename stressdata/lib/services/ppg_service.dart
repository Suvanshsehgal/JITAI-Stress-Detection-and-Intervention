import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/ppg_data.dart';

class PPGService {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  // Signal buffer (15 seconds at ~30 FPS = ~450 samples)
  final List<PPGReading> _signalBuffer = [];
  final int _maxBufferSize = 450;
  final int _minSamplesForBPM = 150; // 5 seconds minimum
  
  // BPM calculation
  int _currentBPM = 0;
  double _confidence = 0.0;
  SignalQuality _signalQuality = SignalQuality.noSignal;
  
  // Timestamps
  DateTime? _lastBPMUpdate;
  
  // Stream controllers
  final _bpmController = StreamController<int>.broadcast();
  final _confidenceController = StreamController<double>.broadcast();
  final _qualityController = StreamController<SignalQuality>.broadcast();
  final _waveformController = StreamController<List<double>>.broadcast();
  final _stateController = StreamController<PPGState>.broadcast();
  
  // Getters
  Stream<int> get bpmStream => _bpmController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;
  Stream<SignalQuality> get qualityStream => _qualityController.stream;
  Stream<List<double>> get waveformStream => _waveformController.stream;
  Stream<PPGState> get stateStream => _stateController.stream;
  
  int get currentBPM => _currentBPM;
  double get confidence => _confidence;
  SignalQuality get signalQuality => _signalQuality;
  bool get isInitialized => _isInitialized;

  /// Initialize camera and start measurement
  Future<bool> initialize() async {
    try {
      _stateController.add(PPGState.initializing);
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _stateController.add(PPGState.error);
        return false;
      }

      // Use back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.low, // Low resolution for performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.torch);
      
      _isInitialized = true;
      
      // Start image stream processing
      _controller!.startImageStream(_processImage);
      
      _stateController.add(PPGState.warmingUp);
      
      // After 5 seconds, switch to measuring state
      Future.delayed(const Duration(seconds: 5), () {
        if (_isInitialized) {
          _stateController.add(PPGState.measuring);
        }
      });
      
      return true;
    } catch (e) {
      debugPrint('PPG initialization error: $e');
      _stateController.add(PPGState.error);
      return false;
    }
  }

  /// Process camera frame and extract PPG signal
  void _processImage(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Extract average red channel intensity
      final redValue = _extractRedChannel(image);
      
      // Add to buffer
      _signalBuffer.add(PPGReading(
        redValue: redValue,
        timestamp: DateTime.now(),
      ));

      // Maintain buffer size
      if (_signalBuffer.length > _maxBufferSize) {
        _signalBuffer.removeAt(0);
      }

      // Update BPM every second
      final now = DateTime.now();
      if (_lastBPMUpdate == null || 
          now.difference(_lastBPMUpdate!).inMilliseconds >= 1000) {
        _calculateBPM();
        _lastBPMUpdate = now;
      }

      // Emit waveform data (last 150 samples for display)
      if (_signalBuffer.length > 10) {
        final displaySamples = _signalBuffer.length > 150 
            ? _signalBuffer.sublist(_signalBuffer.length - 150)
            : _signalBuffer;
        final waveform = displaySamples.map((r) => r.redValue).toList();
        _waveformController.add(waveform);
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Extract average red channel intensity from YUV image
  double _extractRedChannel(CameraImage image) {
    try {
      // YUV420 format: Y plane contains luminance
      // For PPG, we use luminance as proxy for red channel intensity
      final yPlane = image.planes[0];
      final bytes = yPlane.bytes;
      
      // Sample center region (20% of image) for better finger coverage
      final width = image.width;
      final height = image.height;
      final centerX = width ~/ 2;
      final centerY = height ~/ 2;
      final sampleRadius = min(width, height) ~/ 5;
      
      double sum = 0;
      int count = 0;
      
      for (int y = centerY - sampleRadius; y < centerY + sampleRadius; y++) {
        for (int x = centerX - sampleRadius; x < centerX + sampleRadius; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final index = y * width + x;
            if (index < bytes.length) {
              sum += bytes[index];
              count++;
            }
          }
        }
      }
      
      return count > 0 ? sum / count : 0.0;
    } catch (e) {
      debugPrint('Red channel extraction error: $e');
      return 0.0;
    }
  }

  /// Calculate BPM from signal buffer
  void _calculateBPM() {
    if (_signalBuffer.length < _minSamplesForBPM) {
      _signalQuality = SignalQuality.noSignal;
      _qualityController.add(_signalQuality);
      return;
    }

    try {
      // Extract raw signal
      final rawSignal = _signalBuffer.map((r) => r.redValue).toList();
      
      // Signal processing pipeline
      final detrended = _detrend(rawSignal);
      final smoothed = _movingAverage(detrended, 5);
      final filtered = _bandpassFilter(smoothed);
      
      // Peak detection
      final peaks = _detectPeaks(filtered);
      
      // Calculate BPM
      if (peaks.length >= 2) {
        final timeSpan = _signalBuffer.last.timestamp
            .difference(_signalBuffer.first.timestamp)
            .inMilliseconds / 1000.0;
        
        final bpm = ((peaks.length - 1) / timeSpan * 60).round();
        
        // Validate BPM range (40-200 bpm)
        if (bpm >= 40 && bpm <= 200) {
          // Smooth BPM changes
          _currentBPM = _smoothBPM(bpm);
          
          // Calculate confidence and quality
          _confidence = _calculateConfidence(filtered, peaks);
          _signalQuality = _assessSignalQuality(_confidence, filtered);
          
          // Emit updates
          _bpmController.add(_currentBPM);
          _confidenceController.add(_confidence);
          _qualityController.add(_signalQuality);
        } else {
          _signalQuality = SignalQuality.poor;
          _qualityController.add(_signalQuality);
        }
      } else {
        _signalQuality = SignalQuality.poor;
        _qualityController.add(_signalQuality);
      }
    } catch (e) {
      debugPrint('BPM calculation error: $e');
      _signalQuality = SignalQuality.poor;
      _qualityController.add(_signalQuality);
    }
  }

  /// Detrend signal (remove baseline drift)
  List<double> _detrend(List<double> signal) {
    if (signal.isEmpty) return [];
    
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    return signal.map((v) => v - mean).toList();
  }

  /// Moving average smoothing
  List<double> _movingAverage(List<double> signal, int windowSize) {
    if (signal.length < windowSize) return signal;
    
    final result = <double>[];
    for (int i = 0; i < signal.length; i++) {
      final start = max(0, i - windowSize ~/ 2);
      final end = min(signal.length, i + windowSize ~/ 2 + 1);
      final window = signal.sublist(start, end);
      final avg = window.reduce((a, b) => a + b) / window.length;
      result.add(avg);
    }
    return result;
  }

  /// Simple bandpass filter (0.5-4 Hz for heart rate)
  List<double> _bandpassFilter(List<double> signal) {
    // Simplified bandpass: high-pass then low-pass
    final highPassed = _highPassFilter(signal, 0.5);
    final bandPassed = _lowPassFilter(highPassed, 4.0);
    return bandPassed;
  }

  /// High-pass filter
  List<double> _highPassFilter(List<double> signal, double cutoff) {
    if (signal.length < 2) return signal;
    
    final alpha = 0.95; // Simple high-pass coefficient
    final result = <double>[signal[0]];
    
    for (int i = 1; i < signal.length; i++) {
      result.add(alpha * (result[i - 1] + signal[i] - signal[i - 1]));
    }
    return result;
  }

  /// Low-pass filter
  List<double> _lowPassFilter(List<double> signal, double cutoff) {
    if (signal.isEmpty) return signal;
    
    final alpha = 0.1; // Simple low-pass coefficient
    final result = <double>[signal[0]];
    
    for (int i = 1; i < signal.length; i++) {
      result.add(alpha * signal[i] + (1 - alpha) * result[i - 1]);
    }
    return result;
  }

  /// Detect peaks in filtered signal
  List<int> _detectPeaks(List<double> signal) {
    if (signal.length < 3) return [];
    
    final peaks = <int>[];
    final minPeakDistance = 12; // ~0.4s at 30 FPS
    final threshold = _calculateThreshold(signal);
    
    for (int i = 1; i < signal.length - 1; i++) {
      // Check if local maximum
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        // Check if above threshold
        if (signal[i] > threshold) {
          // Check minimum distance from last peak
          if (peaks.isEmpty || i - peaks.last >= minPeakDistance) {
            peaks.add(i);
          }
        }
      }
    }
    
    return peaks;
  }

  /// Calculate adaptive threshold for peak detection
  double _calculateThreshold(List<double> signal) {
    if (signal.isEmpty) return 0.0;
    
    final sorted = List<double>.from(signal)..sort();
    final percentile75 = sorted[(sorted.length * 0.75).floor()];
    return percentile75 * 0.6; // 60% of 75th percentile
  }

  /// Smooth BPM changes to avoid jumps
  int _smoothBPM(int newBPM) {
    if (_currentBPM == 0) return newBPM;
    
    // Exponential moving average
    final alpha = 0.3;
    return (alpha * newBPM + (1 - alpha) * _currentBPM).round();
  }

  /// Calculate confidence score (0-100%)
  double _calculateConfidence(List<double> signal, List<int> peaks) {
    if (peaks.length < 2) return 0.0;
    
    // Calculate signal-to-noise ratio
    final signalPower = signal.map((v) => v * v).reduce((a, b) => a + b) / signal.length;
    final snr = signalPower > 0 ? 10 * log(signalPower) / ln10 : 0;
    
    // Calculate peak regularity
    final peakIntervals = <int>[];
    for (int i = 1; i < peaks.length; i++) {
      peakIntervals.add(peaks[i] - peaks[i - 1]);
    }
    
    final meanInterval = peakIntervals.reduce((a, b) => a + b) / peakIntervals.length;
    final variance = peakIntervals
        .map((v) => pow(v - meanInterval, 2))
        .reduce((a, b) => a + b) / peakIntervals.length;
    final stdDev = sqrt(variance);
    final regularity = meanInterval > 0 ? 1 - (stdDev / meanInterval) : 0;
    
    // Combine metrics
    final confidence = (snr.clamp(0, 20) / 20 * 0.5 + regularity.clamp(0, 1) * 0.5) * 100;
    return confidence.clamp(0, 100);
  }

  /// Assess signal quality based on confidence
  SignalQuality _assessSignalQuality(double confidence, List<double> signal) {
    if (confidence >= 80) return SignalQuality.excellent;
    if (confidence >= 60) return SignalQuality.good;
    if (confidence >= 40) return SignalQuality.fair;
    if (confidence >= 20) return SignalQuality.poor;
    return SignalQuality.noSignal;
  }

  /// Get current measurement result
  PPGResult? getResult() {
    if (_currentBPM == 0 || !_signalQuality.isReliable) return null;
    
    return PPGResult(
      bpm: _currentBPM,
      quality: _signalQuality,
      confidence: _confidence,
      rawSignal: _signalBuffer.map((r) => r.redValue).toList(),
      timestamp: DateTime.now(),
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    _isInitialized = false;
    
    try {
      await _controller?.stopImageStream();
      await _controller?.setFlashMode(FlashMode.off);
      await _controller?.dispose();
    } catch (e) {
      debugPrint('Disposal error: $e');
    }
    
    _controller = null;
    _signalBuffer.clear();
    
    await _bpmController.close();
    await _confidenceController.close();
    await _qualityController.close();
    await _waveformController.close();
    await _stateController.close();
  }
}

extension on SignalQuality {
  bool get isReliable => this == SignalQuality.excellent || this == SignalQuality.good;
}
