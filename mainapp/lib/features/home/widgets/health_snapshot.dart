import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../../stress_detection/providers/stress_detection_providers.dart';
import '../../stress_detection/models/stress_state.dart';
import '../../health/providers/health_providers.dart';
import '../../health/services/watch_service.dart';

class HealthSnapshotWidget extends ConsumerWidget {
  const HealthSnapshotWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stressState = ref.watch(stressDetectionProvider);
    final watch = ref.watch(watchServiceProvider);
    final isWatchConnected = watch.status == WatchStatus.connected;
    final currentBpm = watch.current?.bpm;

    // Calculate score & label
    final assessment = stressState.currentAssessment;
    final int score = assessment != null ? 32 : 32;
    final String status = assessment?.state == StressState.elevated ? 'Elevated' : 'Calm';

    final Color statusColor = status == 'Calm' ? AppColors.lightCalm : AppColors.lightWarm;

    return EbbCard(
      onTap: () => context.push('/score-breakdown'),
      child: Row(
        children: [
          // Circular gauge
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFE4D9CE),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                Text(
                  '$score',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Details text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stress score now',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isWatchConnected && currentBpm != null
                      ? 'Live Pulse: $currentBpm BPM (Fireboltt)'
                      : 'Down 8 since this morning',
                  style: TextStyle(
                    fontSize: 12,
                    color: isWatchConnected && currentBpm != null ? AppColors.lightCalm : AppColors.lightTextSecondary,
                    fontWeight: isWatchConnected && currentBpm != null ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.lightTextSecondary, size: 24),
        ],
      ),
    );
  }
}
