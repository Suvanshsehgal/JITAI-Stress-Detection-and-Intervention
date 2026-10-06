import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../toolbox/providers/session_history_provider.dart';
import 'mood_provider.dart';

class BaselineProgress {
  final int observedDays;
  final int totalCheckIns;
  final int totalInterventions;
  final double progressPercent; // 0.0 to 1.0 (e.g. out of 14 days)
  
  const BaselineProgress({
    required this.observedDays,
    required this.totalCheckIns,
    required this.totalInterventions,
    required this.progressPercent,
  });
}

final baselineProvider = Provider<BaselineProgress>((ref) {
  final moods = ref.watch(moodProvider);
  final sessions = ref.watch(sessionHistoryProvider);
  
  // Calculate unique days with at least one mood check-in
  final uniqueDays = <String>{};
  for (var m in moods) {
    uniqueDays.add('${m.timestamp.year}-${m.timestamp.month}-${m.timestamp.day}');
  }
  
  final observedDays = uniqueDays.length;
  // Let's say 14 days is a "fully learned baseline" for this phase
  final progress = (observedDays / 14.0).clamp(0.0, 1.0);
  
  return BaselineProgress(
    observedDays: observedDays,
    totalCheckIns: moods.length,
    totalInterventions: sessions.length,
    progressPercent: progress,
  );
});
