import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mainapp/core/providers/shared_prefs_provider.dart';
import 'package:mainapp/features/onboarding/onboarding_screen.dart';
import 'package:mainapp/features/onboarding/models/onboarding_state.dart';
import 'package:mainapp/features/onboarding/providers/onboarding_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Onboarding renders first step and has default Pip', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Initial render
    expect(find.text("Hi, I'm your buddy.\nWhat should you call me?"), findsOneWidget);
    
    // Check textfield exists
    expect(find.byType(TextFormField), findsOneWidget);
    
    // Default tone is Gentle
    final choiceChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Gentle'));
    expect(choiceChip.selected, true);
  });

  test('OnboardingNotifier updates state correctly', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    
    final notifier = container.read(onboardingProvider.notifier);
    
    expect(container.read(onboardingProvider).buddyName, 'Pip');
    
    // Update name
    notifier.updateBuddyName('  Test Name  ');
    expect(container.read(onboardingProvider).buddyName, '  Test Name  ');
    
    // Update tone
    notifier.updateTone(BuddyTone.playful);
    expect(container.read(onboardingProvider).tone, BuddyTone.playful);
    
    // Toggle goal
    notifier.toggleGoal('Sleep');
    expect(container.read(onboardingProvider).goals.contains('Sleep'), true);
    notifier.toggleGoal('Sleep');
    expect(container.read(onboardingProvider).goals.contains('Sleep'), false);
    
    // Toggle data pref
    notifier.toggleDataPref('sleep');
    expect(container.read(onboardingProvider).dataPrefs.contains('sleep'), true);
    
    // Complete onboarding (trims name)
    await notifier.completeOnboarding();
    expect(container.read(onboardingProvider).buddyName, 'Test Name');
    expect(container.read(onboardingProvider).isCompleted, true);
    
    // Check preferences saved
    expect(prefs.getString('buddyName'), 'Test Name');
    expect(prefs.getBool('onboardingCompleted'), true);
  });
}
