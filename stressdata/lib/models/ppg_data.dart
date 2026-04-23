import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// Five-level signal quality — mirrors the confidence thresholds in PPGService.
enum SignalQuality {
  excellent,
  good,
  fair,
  poor,
  noSignal;

  /// Human-readable label used in the UI.
  String get label {
    switch (this) {
      case SignalQuality.excellent:
        return 'Excellent Signal';
      case SignalQuality.good:
        return 'Good Signal';
      case SignalQuality.fair:
        return 'Fair Signal — Hold Still';
      case SignalQuality.poor:
        return 'Poor Signal — Adjust Finger';
      case SignalQuality.noSignal:
        return 'No Signal Detected';
    }
  }

  /// Whether the quality level is considered reliable for reporting.
  bool get isReliable =>
      this == SignalQuality.excellent || this == SignalQuality.good;

  /// Numeric rank — useful for comparisons / sorting.
  int get rank {
    switch (this) {
      case SignalQuality.excellent:
        return 4;
      case SignalQuality.good:
        return 3;
      case SignalQuality.fair:
        return 2;
      case SignalQuality.poor:
        return 1;
      case SignalQuality.noSignal:
        return 0;
    }
  }
}

/// Lifecycle state of a PPG measurement session.
enum PPGState {
  initializing,
  warmingUp,
  measuring,
  complete,
  error;

  /// Whether the session is actively collecting samples.
  bool get isActive =>
      this == PPGState.warmingUp || this == PPGState.measuring;
}

/// Clinical BPM category — derived from a measured heart rate.
enum BPMCategory {
  bradycardia,  // < 60 bpm
  normal,       // 60–99 bpm
  elevated,     // 100–119 bpm
  tachycardia;  // ≥ 120 bpm

  static BPMCategory fromBPM(int bpm) {
    if (bpm < 60) return BPMCategory.bradycardia;
    if (bpm < 100) return BPMCategory.normal;
    if (bpm < 120) return BPMCategory.elevated;
    return BPMCategory.tachycardia;
  }

  String get label {
    switch (this) {
      case BPMCategory.bradycardia:
        return 'Low (Bradycardia)';
      case BPMCategory.normal:
        return 'Normal';
      case BPMCategory.elevated:
        return 'Elevated';
      case BPMCategory.tachycardia:
        return 'High (Tachycardia)';
    }
  }

  /// Returns true only for the normal range.
  bool get isNormal => this == BPMCategory.normal;
}

// ─────────────────────────────────────────────────────────────────────────────
// PPGReading  (single camera frame sample)
// ─────────────────────────────────────────────────────────────────────────────

/// One sample extracted from a camera frame.
/// [redValue] is the mean luminance of the centre region (Y-plane proxy).
class PPGReading {
  final double redValue;
  final DateTime timestamp;

  const PPGReading({
    required this.redValue,
    required this.timestamp,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HRVStats  (derived from clean IBIs — produced by PPGService)
// ─────────────────────────────────────────────────────────────────────────────

/// Heart Rate Variability statistics computed from the clean IBI list.
///
/// All values are in **milliseconds** unless noted.
///
/// - [rmssd]   Root Mean Square of Successive Differences — primary HRV metric.
/// - [sdnn]    Standard Deviation of NN intervals.
/// - [meanIBI] Mean inter-beat interval (ms).
/// - [cv]      Coefficient of Variation (sdnn / meanIBI) — dimensionless.
class HRVStats {
  final double rmssd;
  final double sdnn;
  final double meanIBI;
  final double cv;

  const HRVStats({
    required this.rmssd,
    required this.sdnn,
    required this.meanIBI,
    required this.cv,
  });

  /// Compute HRV stats from a list of clean IBIs in **seconds**.
  /// Returns null when there are fewer than 3 intervals (not enough data).
  static HRVStats? fromIBIs(List<double> ibisSeconds) {
    if (ibisSeconds.length < 3) return null;

    // Convert to ms for standard HRV convention
    final ms = ibisSeconds.map((v) => v * 1000.0).toList();

    final mean = ms.reduce((a, b) => a + b) / ms.length;

    // SDNN
    final variance =
        ms.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            ms.length;
    final sdnn = sqrt(variance);

    // RMSSD
    double sumSqDiff = 0;
    for (int i = 1; i < ms.length; i++) {
      final diff = ms[i] - ms[i - 1];
      sumSqDiff += diff * diff;
    }
    final rmssd = sqrt(sumSqDiff / (ms.length - 1));

    final cv = mean > 0 ? sdnn / mean : 0.0;

    return HRVStats(rmssd: rmssd, sdnn: sdnn, meanIBI: mean, cv: cv);
  }

  /// Qualitative HRV interpretation based on RMSSD.
  /// Thresholds are conservative estimates for a resting adult.
  String get interpretation {
    if (rmssd >= 40) return 'Good autonomic balance';
    if (rmssd >= 20) return 'Moderate HRV';
    return 'Low HRV — consider rest';
  }

  @override
  String toString() =>
      'HRVStats(rmssd: ${rmssd.toStringAsFixed(1)} ms, '
      'sdnn: ${sdnn.toStringAsFixed(1)} ms, '
      'meanIBI: ${meanIBI.toStringAsFixed(1)} ms, '
      'cv: ${cv.toStringAsFixed(3)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// PPGResult  (final measurement output)
// ─────────────────────────────────────────────────────────────────────────────

/// The complete result of one PPG measurement session.
///
/// [bpm]        Smoothed, IBI-derived beats per minute.
/// [quality]    Signal quality at time of result.
/// [confidence] 0–100 composite score (SNR + regularity + peak count).
/// [rawSignal]  Full luminance buffer for post-hoc analysis / waveform export.
/// [cleanIBIs]  Outlier-rejected inter-beat intervals in seconds (may be empty).
/// [hrv]        HRV stats derived from [cleanIBIs]; null if insufficient data.
/// [timestamp]  When the result was finalised.
class PPGResult {
  final int bpm;
  final SignalQuality quality;
  final double confidence;
  final List<double> rawSignal;
  final List<double> cleanIBIs;
  final HRVStats? hrv;
  final DateTime timestamp;

  const PPGResult({
    required this.bpm,
    required this.quality,
    required this.confidence,
    required this.rawSignal,
    required this.timestamp,
    this.cleanIBIs = const [],
    this.hrv,
  });

  // ── Derived convenience getters ──────────────────────────────────────────

  /// Clinical category for the measured BPM.
  BPMCategory get category => BPMCategory.fromBPM(bpm);

  /// Legacy accessor — kept for backward compat with existing UI code.
  String get qualityMessage => quality.label;

  /// Whether this result is reliable enough to report to the user.
  bool get isReliable => quality.isReliable && confidence >= 40.0;

  /// Confidence as a 0–1 fraction (for progress indicators etc.).
  double get confidenceFraction => confidence / 100.0;

  // ── copyWith ─────────────────────────────────────────────────────────────

  PPGResult copyWith({
    int? bpm,
    SignalQuality? quality,
    double? confidence,
    List<double>? rawSignal,
    List<double>? cleanIBIs,
    HRVStats? hrv,
    DateTime? timestamp,
  }) {
    return PPGResult(
      bpm: bpm ?? this.bpm,
      quality: quality ?? this.quality,
      confidence: confidence ?? this.confidence,
      rawSignal: rawSignal ?? this.rawSignal,
      cleanIBIs: cleanIBIs ?? this.cleanIBIs,
      hrv: hrv ?? this.hrv,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'bpm': bpm,
        'quality': quality.name,
        'confidence': confidence,
        'category': category.name,
        'isReliable': isReliable,
        'timestamp': timestamp.toIso8601String(),
        'cleanIBIs': cleanIBIs,
        if (hrv != null) ...{
          'hrv_rmssd': hrv!.rmssd,
          'hrv_sdnn': hrv!.sdnn,
          'hrv_meanIBI': hrv!.meanIBI,
          'hrv_cv': hrv!.cv,
        },
      };

  @override
  String toString() =>
      'PPGResult(bpm: $bpm, quality: ${quality.name}, '
      'confidence: ${confidence.toStringAsFixed(1)}%, '
      'category: ${category.name}, hrv: $hrv)';
}