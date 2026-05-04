import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks today's step count using the device pedometer.
///
/// The pedometer gives a cumulative count since the last device reboot.
/// We store a "baseline" (the count at midnight each day) in SharedPreferences
/// and subtract it from the current reading to get today's steps.
class StepService {
  static const _keyBaseline = 'step_baseline_count';
  static const _keyBaselineDate = 'step_baseline_date';

  StreamSubscription<StepCount>? _subscription;

  // Notifier so the UI can react to updates
  final ValueNotifier<int> todaySteps = ValueNotifier(0);

  /// Request permission and start listening to the step counter.
  Future<void> start() async {
    // Android 10+ requires ACTIVITY_RECOGNITION at runtime
    final status = await Permission.activityRecognition.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('⚠️ Activity recognition permission denied');
      return;
    }

    _subscription = Pedometer.stepCountStream.listen(
      _onStep,
      onError: (e) => debugPrint('❌ Pedometer error: $e'),
      cancelOnError: false,
    );
  }

  Future<void> _onStep(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final savedDate = prefs.getString(_keyBaselineDate);

    if (savedDate != today) {
      // New day — reset baseline to current cumulative count
      await prefs.setInt(_keyBaseline, event.steps);
      await prefs.setString(_keyBaselineDate, today);
      todaySteps.value = 0;
    } else {
      final baseline = prefs.getInt(_keyBaseline) ?? event.steps;
      final delta = event.steps - baseline;
      todaySteps.value = delta < 0 ? 0 : delta;
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
