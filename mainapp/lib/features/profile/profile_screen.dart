import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ebb_card.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../insights/providers/baseline_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingProvider);
    final baseline = ref.watch(baselineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Your Preferences',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPrefRow(theme, 'Buddy Name', onboardingState.buddyName),
                    const Divider(height: 24),
                    _buildPrefRow(theme, 'Buddy Tone', onboardingState.tone.name),
                    const Divider(height: 24),
                    _buildPrefRow(theme, 'Data Permissions', onboardingState.dataPrefs.isEmpty ? 'None' : onboardingState.dataPrefs.join(', ')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrefRow(
                      theme,
                      'Baseline Learning',
                      baseline.progressPercent >= 1.0 ? 'Established' : 'Learning in progress',
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

  Widget _buildPrefRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
