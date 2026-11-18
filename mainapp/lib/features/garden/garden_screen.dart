import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/widgets/ebb_card.dart';
import '../../shared/widgets/stillpoint_mascot.dart';

class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Calm Garden'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Center(
                child: StillpointMascot(size: 130),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Reset Garden is Blooming',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Every time you complete a breathing or grounding reset, your companion grows a new leaf.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              EbbCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _GardenStat(count: '12', label: 'Resets Sprouted'),
                    _GardenStat(count: '9', label: 'Days in Bloom'),
                    _GardenStat(count: '4', label: 'Badges Earned'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenStat extends StatelessWidget {
  final String count;
  final String label;

  const _GardenStat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.lightCalm,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
        ),
      ],
    );
  }
}
