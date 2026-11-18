import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../shared/widgets/ebb_button.dart';
import '../../shared/widgets/ebb_card.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Emergency Grounding'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.lightRoseSoft,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.lightRose.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.lightRose, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Take a breath. You are safe.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightRose,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Feel your feet firmly on the floor. Drop your shoulders away from your ears.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightTextPrimary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              EbbButton(
                label: 'Start 2-min Box Breathing',
                isAccent: true,
                onPressed: () {
                  context.replace('/intervention/box-breathing/run');
                },
              ),
              const SizedBox(height: 16),

              EbbButton(
                label: '5-4-3-2-1 Sensory Reset',
                onPressed: () {
                  context.replace('/intervention/54321-grounding/run');
                },
              ),
              const SizedBox(height: 24),

              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need to speak with someone right now?',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Free and confidential helplines are available 24/7.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: EbbButton(
                        label: 'View Support Helplines',
                        isSecondary: true,
                        onPressed: () => context.push('/support'),
                      ),
                    ),
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
