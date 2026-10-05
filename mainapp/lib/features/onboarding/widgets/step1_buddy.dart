import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../models/onboarding_state.dart';

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
    _nameController = TextEditingController(text: initialName == 'Pip' ? '' : initialName);
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, I'm your buddy.\nWhat should you call me?",
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'Buddy Name',
              hintText: 'e.g. Pip',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(onboardingProvider.notifier).updateBuddyName(value);
            },
          ),
          const SizedBox(height: 32),
          Text(
            "What's my tone?",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: BuddyTone.values.map((tone) {
              final isSelected = state.tone == tone;
              final String label;
              switch (tone) {
                case BuddyTone.gentle: label = 'Gentle'; break;
                case BuddyTone.playful: label = 'Playful'; break;
                case BuddyTone.straightTalking: label = 'Straight-talking'; break;
              }
              
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
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
