import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/ebb_orb.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/home_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingProvider);
    final homeState = ref.watch(homeProvider);

    return Column(
      children: [
        const SizedBox(height: 24),
        const EbbOrb(size: 140),
        const SizedBox(height: 24),
        Text(
          'Hi, I\'m ${onboardingState.buddyName}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          homeState.currentWellbeing,
          style: theme.textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
