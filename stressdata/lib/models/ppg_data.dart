/// PPG Signal Quality Levels
enum SignalQuality {
  excellent,
  good,
  fair,
  poor,
  noSignal,
}

/// PPG Measurement State
enum PPGState {
  initializing,
  warmingUp,
  measuring,
  complete,
  error,
}

/// PPG Reading Data Model
class PPGReading {
  final double redValue;
  final DateTime timestamp;

  PPGReading({
    required this.redValue,
    required this.timestamp,
  });
}

/// PPG Measurement Result
class PPGResult {
  final int bpm;
  final SignalQuality quality;
  final double confidence;
  final List<double> rawSignal;
  final DateTime timestamp;

  PPGResult({
    required this.bpm,
    required this.quality,
    required this.confidence,
    required this.rawSignal,
    required this.timestamp,
  });

  String get qualityMessage {
    switch (quality) {
      case SignalQuality.excellent:
        return 'Excellent Signal';
      case SignalQuality.good:
        return 'Good Signal';
      case SignalQuality.fair:
        return 'Fair Signal';
      case SignalQuality.poor:
        return 'Poor Signal - Adjust Finger';
      case SignalQuality.noSignal:
        return 'No Signal Detected';
    }
  }

  bool get isReliable => quality == SignalQuality.excellent || quality == SignalQuality.good;
}
