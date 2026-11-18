import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/widgets/ebb_card.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../insights/providers/baseline_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingProvider);
    final baseline = ref.watch(baselineProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            Text(
              'Intervention & Nudges',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            EbbCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.lightAccentSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_rounded, color: AppColors.lightAccent, size: 20),
                ),
                title: const Text('Nudge Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Sensitivity, quiet hours, and daily limits'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/nudge-settings'),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Data & Context',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            EbbCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.lightPaper, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_outline, color: AppColors.lightTextPrimary, size: 20),
                ),
                title: const Text('Health & Context Signals', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Review permissions, signals, and privacy'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/health'),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Companion Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            EbbCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Companion Name', style: theme.textTheme.bodyLarge),
                      Text(
                        onboardingState.buddyName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Conversational Tone', style: theme.textTheme.bodyLarge),
                      Text(
                        onboardingState.tone.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Baseline Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            EbbCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Observed Days', style: theme.textTheme.bodyLarge),
                      Text(
                        '${baseline.observedDays} days',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: baseline.progressPercent,
                    backgroundColor: AppColors.lightBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightCalm),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    baseline.progressPercent >= 1.0
                        ? 'Baseline patterns established.'
                        : 'Still Point is observing your daily rhythm.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            EbbCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still Point (Stride Probe)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0 (StressLab P-0142 Edition)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Designed for supportive stress intervention. It does not provide medical diagnosis or treatment.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
