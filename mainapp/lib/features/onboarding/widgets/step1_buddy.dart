import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../models/onboarding_state.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';

class Step1Buddy extends ConsumerStatefulWidget {
  const Step1Buddy({super.key});

  @override
  ConsumerState<Step1Buddy> createState() => _Step1BuddyState();
}

class _Step1BuddyState extends ConsumerState<Step1Buddy> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final initialName = ref.read(onboardingProvider).buddyName;
    _nameController = TextEditingController(text: initialName == 'Stillpoint' ? '' : initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Still Point",
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Help us understand stress, one calm check at a time",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Your companion's name",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'e.g. Stillpoint or Pip',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: AppRadius.cardRadius,
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardRadius,
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
            ),
            onChanged: (value) {
              ref.read(onboardingProvider.notifier).updateBuddyName(value);
            },
          ),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Companion tone",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: BuddyTone.values.map((tone) {
              final isSelected = state.tone == tone;
              final String label;
              switch (tone) {
                case BuddyTone.gentle: label = 'Gentle'; break;
                case BuddyTone.playful: label = 'Playful'; break;
                case BuddyTone.straightTalking: label = 'Direct'; break;
              }

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.lightBrand,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pill,
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : AppColors.lightBorder,
                  ),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(onboardingProvider.notifier).updateTone(tone);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
