import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../toolbox/providers/session_history_provider.dart';
import '../../toolbox/providers/intervention_provider.dart';

class InterventionUsage {
  final int totalCompleted;
  final String mostFrequentTitle;
  
  const InterventionUsage({
    required this.totalCompleted,
    required this.mostFrequentTitle,
  });
}

final interventionUsageProvider = Provider<InterventionUsage>((ref) {
  final sessions = ref.watch(sessionHistoryProvider);
  final catalog = ref.watch(interventionCatalogProvider);
  
  if (sessions.isEmpty) {
    return const InterventionUsage(totalCompleted: 0, mostFrequentTitle: 'None yet');
  }
  
  final counts = <String, int>{};
  for (var s in sessions) {
    counts[s.interventionId] = (counts[s.interventionId] ?? 0) + 1;
  }
  
  String mostFrequentId = counts.keys.first;
  int maxCount = counts[mostFrequentId]!;
  
  for (var entry in counts.entries) {
    if (entry.value > maxCount) {
      mostFrequentId = entry.key;
      maxCount = entry.value;
    }
  }
  
  final mostFrequentTitle = catalog
      .cast<dynamic>()
      .firstWhere((i) => i.id == mostFrequentId, orElse: () => null)
      ?.title ?? 'Unknown';

  return InterventionUsage(
    totalCompleted: sessions.length,
    mostFrequentTitle: mostFrequentTitle,
  );
});
