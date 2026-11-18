import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../../health/providers/health_providers.dart';
import '../../health/services/watch_service.dart';

class ScoreBreakdownScreen extends ConsumerWidget {
  final int score;
  final String status;

  const ScoreBreakdownScreen({
    super.key,
    this.score = 32,
    this.status = 'Calm',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final watch = ref.watch(watchServiceProvider);

    final metrics = [
      {'label': 'Heart rate change', 'value': 30},
      {'label': 'Heart rate variability', 'value': 24},
      {'label': 'Stroop performance', 'value': 38},
      {'label': 'Memory', 'value': 28},
      {'label': 'Pattern', 'value': 22},
      {'label': 'Movement and sensors', 'value': 40},
      {'label': 'WHO-5 wellbeing', 'value': 34},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Score Breakdown'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // 1. Circular gauge
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: score / 100.0,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.lightBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightCalm),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.lightCalm,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (watch.status == WatchStatus.connected && watch.current != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightCalmSoft,
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: AppColors.lightCalm.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.watch_rounded, size: 16, color: AppColors.lightCalm),
                        const SizedBox(width: 8),
                        Text(
                          'Fireboltt Live Pulse: ${watch.current!.bpm} BPM',
                          style: const TextStyle(
                            color: AppColors.lightCalm,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 2. Segmented Range Indicator
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 33,
                          child: SizedBox(height: 8, child: ColoredBox(color: AppColors.lightCalm)),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 33,
                          child: SizedBox(height: 8, child: ColoredBox(color: AppColors.lightWarm)),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 34,
                          child: SizedBox(height: 8, child: ColoredBox(color: AppColors.lightRose)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calm 0–33',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightCalm,
                        ),
                      ),
                      Text(
                        'Moderate 34–66',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightWarm,
                        ),
                      ),
                      Text(
                        'High 67–100',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightRose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. What shaped your score card
              EbbCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What shaped your score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...metrics.map((item) {
                      final label = item['label'] as String;
                      final val = item['value'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$val',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: val / 100.0,
                                minHeight: 7,
                                backgroundColor: AppColors.lightBorder,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightCalm),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Footnote disclaimer
              Text(
                'Higher means more stress. For wellbeing only, not a medical diagnosis.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
