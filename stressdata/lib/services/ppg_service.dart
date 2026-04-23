import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/ppg_data.dart';

/// Optimized PPG Service with:
/// - 4th-order Butterworth IIR bandpass filter (0.5–3.5 Hz)
/// - Linear detrending (least-squares) instead of mean subtraction
/// - IBI (Inter-Beat Interval) based BPM — more accurate than peak-count/time
/// - Adaptive peak detection with physiological refractory period
/// - Median-based outlier rejection on beat intervals
/// - Proper SNR using signal vs residual noise power
/// - Welford's online variance for efficient stats
class PPGService {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;

  // ─── Buffer Configuration ────────────────────────────────────────────────
  // 15 s at ~30 FPS. We track actual timestamps, so FPS drift is handled.
  final List<PPGReading> _signalBuffer = [];
  final int _maxBufferSize = 450;
  final int _minSamplesForBPM = 150; // 5 s minimum before first estimate

  // ─── State ───────────────────────────────────────────────────────────────
  int _currentBPM = 0;
  double _confidence = 0.0;
  SignalQuality _signalQuality = SignalQuality.noSignal;
  DateTime? _lastBPMUpdate;

  // BPM history for temporal smoothing (keep last 5 valid estimates)
  final List<int> _bpmHistory = [];
  static const int _bpmHistorySize = 5;

  // Last accepted clean IBI list — exposed via getResult()
  List<double> _lastCleanIBIs = [];

  // ─── Streams ─────────────────────────────────────────────────────────────
  final _bpmController = StreamController<int>.broadcast();
  final _confidenceController = StreamController<double>.broadcast();
  final _qualityController = StreamController<SignalQuality>.broadcast();
  final _waveformController = StreamController<List<double>>.broadcast();
  final _stateController = StreamController<PPGState>.broadcast();

  Stream<int> get bpmStream => _bpmController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;
  Stream<SignalQuality> get qualityStream => _qualityController.stream;
  Stream<List<double>> get waveformStream => _waveformController.stream;
  Stream<PPGState> get stateStream => _stateController.stream;

  int get currentBPM => _currentBPM;
  double get confidence => _confidence;
  SignalQuality get signalQuality => _signalQuality;
  bool get isInitialized => _isInitialized;

  // ─── IIR Filter State ────────────────────────────────────────────────────
  // 4th-order Butterworth bandpass implemented as two biquad sections (SOS).
  // Pre-computed for Fs=30 Hz, passband 0.5–3.5 Hz.
  // Each row: [b0, b1, b2, a1, a2]  (a0 normalised to 1)
  //
  // Generated with scipy:
  //   sos = signal.butter(2, [0.5, 3.5], btype='bandpass', fs=30, output='sos')
  static const List<List<double>> _butterSOS = [
    // Section 1
    [0.05960692, 0.0, -0.05960692, -1.72971020, 0.76647482],
    // Section 2
    [1.0, 0.0, -1.0, -1.87774685, 0.88079258],
  ];

  // Per-section delay registers [w1, w2]
  final List<List<double>> _sosDelay = [
    [0.0, 0.0],
    [0.0, 0.0],
  ];

  // ─── Initialization ───────────────────────────────────────────────────────
  Future<bool> initialize() async {
    try {
      _stateController.add(PPGState.initializing);

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _stateController.add(PPGState.error);
        return false;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.torch);

      _isInitialized = true;
      _controller!.startImageStream(_processImage);
      _stateController.add(PPGState.warmingUp);

      Future.delayed(const Duration(seconds: 5), () {
        if (_isInitialized) _stateController.add(PPGState.measuring);
      });

      return true;
    } catch (e) {
      debugPrint('PPG init error: $e');
      _stateController.add(PPGState.error);
      return false;
    }
  }

  // ─── Frame Processing ─────────────────────────────────────────────────────
  void _processImage(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final redValue = _extractRedChannel(image);
      final now = DateTime.now();

      _signalBuffer.add(PPGReading(redValue: redValue, timestamp: now));
      if (_signalBuffer.length > _maxBufferSize) _signalBuffer.removeAt(0);

      // Update BPM every ~1 s
      if (_lastBPMUpdate == null ||
          now.difference(_lastBPMUpdate!).inMilliseconds >= 1000) {
        _calculateBPM();
        _lastBPMUpdate = now;
      }

      // Emit waveform (last 5 s ≈ 150 samples)
      if (_signalBuffer.length > 10) {
        final start = max(0, _signalBuffer.length - 150);
        final waveform =
            _signalBuffer.sublist(start).map((r) => r.redValue).toList();
        _waveformController.add(waveform);
      }
    } catch (e) {
      debugPrint('Frame error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // ─── Red Channel Extraction ───────────────────────────────────────────────
  /// Samples the centre 20 % of the Y (luminance) plane.
  /// Luminance ≈ 0.299 R + 0.587 G + 0.114 B. With torch + finger,
  /// the red channel dominates, so Y is a reliable proxy.
  double _extractRedChannel(CameraImage image) {
    try {
      final yPlane = image.planes[0];
      final bytes = yPlane.bytes;
      final width = image.width;
      final height = image.height;
      final stride = yPlane.bytesPerRow;

      final cx = width ~/ 2;
      final cy = height ~/ 2;
      final r = min(width, height) ~/ 5; // 20 % radius

      double sum = 0;
      int count = 0;

      for (int y = cy - r; y < cy + r; y++) {
        for (int x = cx - r; x < cx + r; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final idx = y * stride + x;
            if (idx < bytes.length) {
              sum += bytes[idx] & 0xFF;
              count++;
            }
          }
        }
      }

      return count > 0 ? sum / count : 0.0;
    } catch (e) {
      debugPrint('Channel extraction error: $e');
      return 0.0;
    }
  }

  // ─── BPM Calculation ──────────────────────────────────────────────────────
  void _calculateBPM() {
    if (_signalBuffer.length < _minSamplesForBPM) {
      _emit(SignalQuality.noSignal, 0, 0.0);
      return;
    }

    try {
      final rawSignal = _signalBuffer.map((r) => r.redValue).toList();

      // Estimate actual sample rate from timestamps
      final fs = _estimateSampleRate();

      // 1. Linear detrend (removes slow baseline wander)
      final detrended = _linearDetrend(rawSignal);

      // 2. Online IIR Butterworth bandpass (0.5–3.5 Hz)
      //    We re-run the full buffer through a fresh filter instance each
      //    update to avoid phase artefacts from accumulated state drift.
      final filtered = _butterworthBandpass(detrended);

      // 3. Peak detection with physiological refractory period
      final peaks = _detectPeaks(filtered, fs);

      if (peaks.length < 3) {
        _emit(SignalQuality.poor, _currentBPM, 0.0);
        return;
      }

      // 4. Compute IBIs and reject outliers
      final ibis = _computeIBIs(peaks, fs);
      final cleanIBIs = _rejectOutliers(ibis);
      if (cleanIBIs.isNotEmpty) _lastCleanIBIs = List.unmodifiable(cleanIBIs);

      if (cleanIBIs.isEmpty) {
        _emit(SignalQuality.poor, _currentBPM, 0.0);
        return;
      }

      // 5. BPM from median IBI  (robust to single-beat errors)
      final medianIBI = _median(cleanIBIs); // seconds
      final rawBPM = (60.0 / medianIBI).round();

      if (rawBPM < 40 || rawBPM > 200) {
        _emit(SignalQuality.poor, _currentBPM, 0.0);
        return;
      }

      // 6. Temporal smoothing via weighted moving average of BPM history
      _bpmHistory.add(rawBPM);
      if (_bpmHistory.length > _bpmHistorySize) _bpmHistory.removeAt(0);
      final smoothedBPM = _weightedBPMAverage();

      // 7. Confidence & quality
      final conf = _calculateConfidence(filtered, cleanIBIs, fs);
      final quality = _assessQuality(conf);

      _currentBPM = smoothedBPM;
      _confidence = conf;
      _signalQuality = quality;

      _bpmController.add(_currentBPM);
      _confidenceController.add(_confidence);
      _qualityController.add(_signalQuality);
    } catch (e) {
      debugPrint('BPM calc error: $e');
      _emit(SignalQuality.poor, _currentBPM, 0.0);
    }
  }

  // ─── Sample Rate Estimation ───────────────────────────────────────────────
  /// Actual FPS may differ from 30; compute from buffer timestamps.
  double _estimateSampleRate() {
    if (_signalBuffer.length < 2) return 30.0;
    final spanMs = _signalBuffer.last.timestamp
        .difference(_signalBuffer.first.timestamp)
        .inMilliseconds;
    if (spanMs <= 0) return 30.0;
    return (_signalBuffer.length - 1) / (spanMs / 1000.0);
  }

  // ─── Linear Detrend ───────────────────────────────────────────────────────
  /// Least-squares line fit removed from signal — handles slow DC drift
  /// far better than mean subtraction.
  List<double> _linearDetrend(List<double> signal) {
    final n = signal.length;
    if (n < 2) return signal;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += signal[i];
      sumXY += i * signal[i];
      sumX2 += i * i.toDouble();
    }

    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) {
      final mean = sumY / n;
      return signal.map((v) => v - mean).toList();
    }

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;

    return List.generate(n, (i) => signal[i] - (slope * i + intercept));
  }

  // ─── Butterworth IIR Bandpass ─────────────────────────────────────────────
  /// Direct-Form II transposed biquad cascade.
  /// Runs a fresh pass over the full buffer (stateless per call) to avoid
  /// accumulated numerical drift in long-running state registers.
  List<double> _butterworthBandpass(List<double> signal) {
    // Fresh delay registers for this pass
    final w = [
      [0.0, 0.0],
      [0.0, 0.0],
    ];

    final out = List<double>.filled(signal.length, 0.0);

    for (int n = 0; n < signal.length; n++) {
      double x = signal[n];

      for (int s = 0; s < _butterSOS.length; s++) {
        final b0 = _butterSOS[s][0];
        final b1 = _butterSOS[s][1];
        final b2 = _butterSOS[s][2];
        final a1 = _butterSOS[s][3];
        final a2 = _butterSOS[s][4];

        // Direct-Form II Transposed
        final y = b0 * x + w[s][0];
        w[s][0] = b1 * x - a1 * y + w[s][1];
        w[s][1] = b2 * x - a2 * y;
        x = y;
      }

      out[n] = x;
    }

    return out;
  }

  // ─── Peak Detection ───────────────────────────────────────────────────────
  /// Adaptive threshold + physiological refractory period.
  ///
  /// Refractory period = 60/200 s = 0.3 s → no two peaks within 0.3 s
  /// (corresponds to 200 BPM max). Threshold adapts every 3 s window.
  List<int> _detectPeaks(List<double> signal, double fs) {
    if (signal.length < 3) return [];

    // Physiological minimum distance between beats (200 BPM max)
    final minDist = (fs * 0.30).ceil(); // samples

    // Adaptive threshold: mean + 0.5 * std over a sliding 3 s window
    final windowSamples = (fs * 3).round();
    final peaks = <int>[];

    for (int i = 1; i < signal.length - 1; i++) {
      // Local maximum check
      if (signal[i] <= signal[i - 1] || signal[i] <= signal[i + 1]) continue;

      // Compute adaptive threshold over local window
      final wStart = max(0, i - windowSamples ~/ 2);
      final wEnd = min(signal.length, i + windowSamples ~/ 2);
      final window = signal.sublist(wStart, wEnd);
      final mean = window.reduce((a, b) => a + b) / window.length;
      final std = _std(window, mean);
      final threshold = mean + 0.5 * std;

      if (signal[i] <= threshold) continue;

      // Refractory period
      if (peaks.isNotEmpty && i - peaks.last < minDist) continue;

      peaks.add(i);
    }

    return peaks;
  }

  // ─── IBI Computation ─────────────────────────────────────────────────────
  /// Converts peak indices → inter-beat intervals in seconds.
  List<double> _computeIBIs(List<int> peaks, double fs) {
    final ibis = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      ibis.add((peaks[i] - peaks[i - 1]) / fs);
    }
    return ibis;
  }

  // ─── Outlier Rejection ────────────────────────────────────────────────────
  /// Removes IBIs that deviate more than 20 % from the median.
  /// This tolerates occasional ectopic beats without skewing the average.
  List<double> _rejectOutliers(List<double> ibis) {
    if (ibis.isEmpty) return ibis;
    final med = _median(ibis);
    return ibis.where((v) => (v - med).abs() / med <= 0.20).toList();
  }

  // ─── BPM Temporal Smoothing ───────────────────────────────────────────────
  /// Linearly weighted moving average — recent estimates count more.
  int _weightedBPMAverage() {
    if (_bpmHistory.isEmpty) return _currentBPM;
    double weightedSum = 0;
    double weightTotal = 0;
    for (int i = 0; i < _bpmHistory.length; i++) {
      final w = (i + 1).toDouble(); // weight 1…N
      weightedSum += _bpmHistory[i] * w;
      weightTotal += w;
    }
    return (weightedSum / weightTotal).round();
  }

  // ─── Confidence Scoring ───────────────────────────────────────────────────
  /// Combines three orthogonal quality metrics:
  ///
  /// 1. **SNR** – ratio of filtered signal power to residual (noise = raw - filtered)
  /// 2. **IBI regularity** – coefficient of variation of clean IBIs
  /// 3. **Peak count sufficiency** – more peaks → higher certainty
  double _calculateConfidence(
      List<double> filtered, List<double> cleanIBIs, double fs) {
    if (cleanIBIs.isEmpty) return 0.0;

    // 1. SNR: signal power / noise power
    final rawForSNR = _signalBuffer.map((r) => r.redValue).toList();
    final detrended = _linearDetrend(rawForSNR);
    double sigPow = 0, noisePow = 0;
    final len = min(filtered.length, detrended.length);
    for (int i = 0; i < len; i++) {
      sigPow += filtered[i] * filtered[i];
      final noise = detrended[i] - filtered[i];
      noisePow += noise * noise;
    }
    sigPow /= len;
    noisePow /= len;
    // SNR in dB, clamp to [0, 20] then normalise
    final snrDB =
        (noisePow > 0) ? 10 * log(sigPow / noisePow) / ln10 : 20.0;
    final snrScore = snrDB.clamp(0.0, 20.0) / 20.0; // 0–1

    // 2. IBI regularity: 1 - CV  (CV = std/mean)
    final mean = cleanIBIs.reduce((a, b) => a + b) / cleanIBIs.length;
    final std = _std(cleanIBIs.map((v) => v).toList(), mean);
    final cv = mean > 0 ? std / mean : 1.0;
    final regularityScore = (1.0 - cv).clamp(0.0, 1.0);

    // 3. Peak count: saturates at 8 peaks (≈ 8 beats in buffer)
    final peakScore = (cleanIBIs.length / 8.0).clamp(0.0, 1.0);

    // Weighted combination
    final confidence = (snrScore * 0.40 + regularityScore * 0.45 + peakScore * 0.15) * 100.0;
    return confidence.clamp(0.0, 100.0);
  }

  // ─── Quality Assessment ───────────────────────────────────────────────────
  SignalQuality _assessQuality(double confidence) {
    if (confidence >= 75) return SignalQuality.excellent;
    if (confidence >= 55) return SignalQuality.good;
    if (confidence >= 35) return SignalQuality.fair;
    if (confidence >= 15) return SignalQuality.poor;
    return SignalQuality.noSignal;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  double _median(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double _std(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return sqrt(variance);
  }

  void _emit(SignalQuality quality, int bpm, double conf) {
    _signalQuality = quality;
    _confidence = conf;
    _qualityController.add(quality);
    if (bpm > 0) _bpmController.add(bpm);
    _confidenceController.add(conf);
  }

  // ─── Public API ───────────────────────────────────────────────────────────
  PPGResult? getResult() {
    if (_currentBPM == 0 || !_signalQuality.isReliable) return null;
    return PPGResult(
      bpm: _currentBPM,
      quality: _signalQuality,
      confidence: _confidence,
      rawSignal: _signalBuffer.map((r) => r.redValue).toList(),
      cleanIBIs: List<double>.from(_lastCleanIBIs),
      hrv: HRVStats.fromIBIs(_lastCleanIBIs),
      timestamp: DateTime.now(),
    );
  }

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
    _bpmHistory.clear();
    _lastCleanIBIs = [];
    _resetFilterState();

    await _bpmController.close();
    await _confidenceController.close();
    await _qualityController.close();
    await _waveformController.close();
    await _stateController.close();
  }

  void _resetFilterState() {
    for (final d in _sosDelay) {
      d[0] = 0.0;
      d[1] = 0.0;
    }
  }
}

extension on SignalQuality {
  bool get isReliable =>
      this == SignalQuality.excellent || this == SignalQuality.good;
}