import 'package:flutter/foundation.dart';
import '../models/ppg_data.dart';

/// Helper class for testing and debugging PPG functionality
class PPGTestHelper {
  /// Validate BPM is within normal range
  static bool isValidBPM(int bpm) {
    return bpm >= 40 && bpm <= 200;
  }

  /// Get BPM category
  static String getBPMCategory(int bpm) {
    if (bpm < 60) return 'Low (Bradycardia)';
    if (bpm <= 100) return 'Normal';
    if (bpm <= 120) return 'Elevated';
    return 'High (Tachycardia)';
  }

  /// Calculate expected measurement time
  static Duration getExpectedDuration({
    int warmupSeconds = 5,
    int measurementSeconds = 30,
  }) {
    return Duration(seconds: warmupSeconds + measurementSeconds);
  }

  /// Log PPG result for debugging
  static void logResult(PPGResult result) {
    if (kDebugMode) {
      print('=== PPG Measurement Result ===');
      print('BPM: ${result.bpm}');
      print('Quality: ${result.quality.name}');
      print('Confidence: ${result.confidence.toStringAsFixed(1)}%');
      print('Category: ${getBPMCategory(result.bpm)}');
      print('Timestamp: ${result.timestamp}');
      print('Signal Samples: ${result.rawSignal.length}');
      print('============================');
    }
  }

  /// Validate signal quality
  static bool isReliableReading(PPGResult result) {
    return result.isReliable && 
           isValidBPM(result.bpm) && 
           result.confidence >= 60;
  }

  /// Get quality color for UI
  static String getQualityColorHex(SignalQuality quality) {
    switch (quality) {
      case SignalQuality.excellent:
        return '#4CAF50'; // Green
      case SignalQuality.good:
        return '#8BC34A'; // Light Green
      case SignalQuality.fair:
        return '#FF9800'; // Orange
      case SignalQuality.poor:
        return '#F44336'; // Red
      case SignalQuality.noSignal:
        return '#9E9E9E'; // Grey
    }
  }

  /// Calculate heart rate zone (for fitness apps)
  static String getHeartRateZone(int bpm, int age) {
    final maxHR = 220 - age;
    final percentage = (bpm / maxHR) * 100;

    if (percentage < 50) return 'Very Light';
    if (percentage < 60) return 'Light';
    if (percentage < 70) return 'Moderate';
    if (percentage < 80) return 'Hard';
    if (percentage < 90) return 'Very Hard';
    return 'Maximum';
  }

  /// Estimate calories burned per minute (rough approximation)
  static double estimateCaloriesPerMinute(int bpm, double weightKg) {
    // Very rough estimation: higher HR = more calories
    // This is a simplified formula and not medically accurate
    return (bpm * weightKg * 0.0001);
  }

  /// Check if measurement shows signs of stress
  static bool indicatesStress(int restingBPM, int currentBPM) {
    final increase = currentBPM - restingBPM;
    return increase > 20; // 20+ BPM increase may indicate stress
  }

  /// Generate test report
  static String generateReport(PPGResult result, {int? age}) {
    final buffer = StringBuffer();
    buffer.writeln('Heart Rate Measurement Report');
    buffer.writeln('=' * 40);
    buffer.writeln('BPM: ${result.bpm}');
    buffer.writeln('Category: ${getBPMCategory(result.bpm)}');
    buffer.writeln('Quality: ${result.qualityMessage}');
    buffer.writeln('Confidence: ${result.confidence.toStringAsFixed(1)}%');
    
    if (age != null) {
      buffer.writeln('HR Zone: ${getHeartRateZone(result.bpm, age)}');
    }
    
    buffer.writeln('Timestamp: ${result.timestamp}');
    buffer.writeln('Reliable: ${isReliableReading(result) ? "Yes" : "No"}');
    buffer.writeln('=' * 40);
    
    return buffer.toString();
  }
}
