import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/ppg_data.dart';

/// Utility helpers for PPG measurement validation, UI support, and reporting.
///
/// Design rules:
/// - BPM range / category logic lives in [BPMCategory] (ppg_data.dart).
///   Helper methods here delegate to it — no duplicated thresholds.
/// - Quality color / label logic lives in [SignalQuality].
///   Helpers here only do Flutter-specific mapping (Color objects).
/// - Pure functions only — no state, no side effects except [logResult].
class PPGTestHelper {
  PPGTestHelper._(); // prevent instantiation

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Returns true when [bpm] is within the detectable physiological range.
  static bool isValidBPM(int bpm) => bpm >= 40 && bpm <= 200;

  /// Returns true when the result is reliable enough to present to the user.
  ///
  /// Uses [PPGResult.isReliable] (quality + confidence ≥ 40 %) as the base,
  /// then adds a stricter confidence floor of 55 % for the helper layer.
  static bool isReliableReading(PPGResult result) {
    return result.isReliable &&
        isValidBPM(result.bpm) &&
        result.confidence >= 55.0;
  }

  // ─── BPM / Category ──────────────────────────────────────────────────────

  /// Human-readable BPM category. Delegates to [BPMCategory] — single source
  /// of truth for range thresholds.
  static String getBPMCategory(int bpm) => BPMCategory.fromBPM(bpm).label;

  /// Heart-rate training zone based on age-predicted max HR (220 − age).
  ///
  /// Returns a [HeartRateZone] with name, % range, and coaching note.
  static HeartRateZone getHeartRateZone(int bpm, int age) {
    assert(age > 0 && age < 130, 'Age must be a plausible value');
    final maxHR = 220 - age;
    final pct = (bpm / maxHR).clamp(0.0, 1.0);
    return HeartRateZone.fromFraction(pct);
  }

  /// Returns true when [currentBPM] is ≥ 20 BPM above [restingBPM],
  /// a simple heuristic for acute physiological stress.
  static bool indicatesStress(int restingBPM, int currentBPM) =>
      (currentBPM - restingBPM) >= 20;

  /// Rough calorie burn estimate (kcal / min).
  ///
  /// Uses a simplified METs-like proxy. Not medically validated —
  /// suitable only for fitness-app ballpark figures.
  static double estimateCaloriesPerMinute(int bpm, double weightKg) {
    assert(weightKg > 0);
    // Empirical constant chosen so 70 kg @ 140 bpm ≈ 9 kcal/min
    return (bpm * weightKg * 0.000918).clamp(0.0, 25.0);
  }

  // ─── UI Helpers ──────────────────────────────────────────────────────────

  /// Flutter [Color] for a given [SignalQuality] level.
  /// Consistent with the hex values previously in this file.
  static Color qualityColor(SignalQuality quality) {
    switch (quality) {
      case SignalQuality.excellent:
        return const Color(0xFF4CAF50); // Green
      case SignalQuality.good:
        return const Color(0xFF8BC34A); // Light green
      case SignalQuality.fair:
        return const Color(0xFFFF9800); // Orange
      case SignalQuality.poor:
        return const Color(0xFFF44336); // Red
      case SignalQuality.noSignal:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Hex string version — kept for callers that need a raw string (e.g. web).
  static String qualityColorHex(SignalQuality quality) {
    return '#${qualityColor(quality).value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Expected total session duration.
  static Duration getExpectedDuration({
    int warmupSeconds = 5,
    int measurementSeconds = 30,
  }) =>
      Duration(seconds: warmupSeconds + measurementSeconds);

  // ─── Reporting ────────────────────────────────────────────────────────────

  /// Structured plain-text report suitable for display or export.
  ///
  /// Includes HRV section when the result contains clean IBI data.
  /// Pass [age] to add HR zone information.
  static String generateReport(PPGResult result, {int? age}) {
    final buf = StringBuffer();
    final sep = '─' * 42;

    buf.writeln('Heart Rate Measurement Report');
    buf.writeln(sep);

    // ── Core metrics ──
    buf.writeln('BPM          : ${result.bpm}');
    buf.writeln('Category     : ${result.category.label}');
    buf.writeln('Quality      : ${result.qualityMessage}');
    buf.writeln('Confidence   : ${result.confidence.toStringAsFixed(1)} %');
    buf.writeln('Reliable     : ${isReliableReading(result) ? "Yes" : "No"}');

    // ── HR zone (optional) ──
    if (age != null) {
      final zone = getHeartRateZone(result.bpm, age);
      buf.writeln('HR Zone      : ${zone.name}  (${zone.rangeLabel})');
      buf.writeln('Zone Note    : ${zone.note}');
    }

    // ── HRV section (only when IBI data is available) ──
    if (result.hrv != null) {
      buf.writeln(sep);
      buf.writeln('HRV (short-term)');
      buf.writeln('  RMSSD      : ${result.hrv!.rmssd.toStringAsFixed(1)} ms');
      buf.writeln('  SDNN       : ${result.hrv!.sdnn.toStringAsFixed(1)} ms');
      buf.writeln('  Mean IBI   : ${result.hrv!.meanIBI.toStringAsFixed(1)} ms');
      buf.writeln('  CV         : ${(result.hrv!.cv * 100).toStringAsFixed(1)} %');
      buf.writeln('  Assessment : ${result.hrv!.interpretation}');
    }

    // ── Meta ──
    buf.writeln(sep);
    buf.writeln('Samples      : ${result.rawSignal.length}');
    buf.writeln('Timestamp    : ${result.timestamp.toLocal()}');
    buf.writeln(sep);

    return buf.toString();
  }

  // ─── Debug Logging ────────────────────────────────────────────────────────

  /// Prints a structured result summary in debug builds only.
  static void logResult(PPGResult result, {int? age}) {
    if (!kDebugMode) return;

    debugPrint('╔══ PPG Result ══════════════════════════╗');
    debugPrint('║ BPM        : ${result.bpm.toString().padRight(28)}║');
    debugPrint('║ Category   : ${result.category.name.padRight(28)}║');
    debugPrint('║ Quality    : ${result.quality.name.padRight(28)}║');
    debugPrint(
        '║ Confidence : ${'${result.confidence.toStringAsFixed(1)} %'.padRight(28)}║');
    debugPrint(
        '║ Reliable   : ${'${isReliableReading(result)}'.padRight(28)}║');

    if (result.hrv != null) {
      debugPrint(
          '║ RMSSD      : ${'${result.hrv!.rmssd.toStringAsFixed(1)} ms'.padRight(28)}║');
      debugPrint(
          '║ SDNN       : ${'${result.hrv!.sdnn.toStringAsFixed(1)} ms'.padRight(28)}║');
    }

    if (age != null) {
      final zone = getHeartRateZone(result.bpm, age);
      debugPrint('║ HR Zone    : ${zone.name.padRight(28)}║');
    }

    debugPrint('╚════════════════════════════════════════╝');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeartRateZone  (value type — replaces the bare String return)
// ─────────────────────────────────────────────────────────────────────────────

/// A heart-rate training zone with name, percentage range, and coaching note.
class HeartRateZone {
  final String name;

  /// Low end of the zone as a fraction of max HR (0–1).
  final double lowFraction;

  /// High end of the zone as a fraction of max HR (0–1).
  final double highFraction;

  /// Short coaching note shown to the user.
  final String note;

  const HeartRateZone._({
    required this.name,
    required this.lowFraction,
    required this.highFraction,
    required this.note,
  });

  /// Display string, e.g. "50 – 60 %".
  String get rangeLabel =>
      '${(lowFraction * 100).round()} – ${(highFraction * 100).round()} %';

  /// Selects the correct zone from a 0–1 fraction of age-predicted max HR.
  static HeartRateZone fromFraction(double pct) {
    if (pct < 0.50) {
      return const HeartRateZone._(
        name: 'Very Light',
        lowFraction: 0.00,
        highFraction: 0.50,
        note: 'Rest or very easy activity.',
      );
    } else if (pct < 0.60) {
      return const HeartRateZone._(
        name: 'Light',
        lowFraction: 0.50,
        highFraction: 0.60,
        note: 'Improves basic endurance and fat metabolism.',
      );
    } else if (pct < 0.70) {
      return const HeartRateZone._(
        name: 'Moderate',
        lowFraction: 0.60,
        highFraction: 0.70,
        note: 'Aerobic base building — comfortable conversation pace.',
      );
    } else if (pct < 0.80) {
      return const HeartRateZone._(
        name: 'Hard',
        lowFraction: 0.70,
        highFraction: 0.80,
        note: 'Improves aerobic capacity — slightly breathless.',
      );
    } else if (pct < 0.90) {
      return const HeartRateZone._(
        name: 'Very Hard',
        lowFraction: 0.80,
        highFraction: 0.90,
        note: 'High-intensity training — speech difficult.',
      );
    } else {
      return const HeartRateZone._(
        name: 'Maximum',
        lowFraction: 0.90,
        highFraction: 1.00,
        note: 'Near maximum effort — unsustainable for long.',
      );
    }
  }
}