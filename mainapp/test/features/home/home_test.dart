import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mainapp/features/home/home_screen.dart';
import 'package:mainapp/features/home/widgets/health_snapshot.dart';
import 'package:mainapp/features/home/widgets/mood_checkin.dart';
import 'package:mainapp/features/home/widgets/suggested_action.dart';
import 'package:mainapp/features/home/widgets/why_now.dart';
import 'package:mainapp/features/home/widgets/baseline_progress.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'buddyName': 'Pip Test'});
  });

  testWidgets('Home renders all sections with mock data', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify buddy name is picked up
    expect(find.text("Hi, I'm Pip Test"), findsOneWidget);

    // Verify sections exist
    expect(find.byType(HealthSnapshotWidget), findsOneWidget);
    expect(find.byType(SuggestedActionWidget), findsOneWidget);
    expect(find.byType(WhyNowWidget), findsOneWidget);
    expect(find.byType(MoodCheckInWidget), findsOneWidget);
    expect(find.byType(BaselineProgressWidget), findsOneWidget);

    // Verify default mock values
    expect(find.text('68 bpm', skipOffstage: false), findsOneWidget); // Default HR
    expect(find.text('Box Breathing', skipOffstage: false), findsOneWidget); // Default suggestion
    expect(find.text('40%', skipOffstage: false), findsOneWidget); // Default 0.4 progress
  });

  testWidgets('Mood check-in updates state correctly', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Scroll to the MoodCheckIn widget so it's visible
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();

    // Tap 'Good' mood
    await tester.tap(find.text('Good'), warnIfMissed: false);
    await tester.pump();

    // Tap 'Low' to verify it works without crashing
    await tester.tap(find.text('Low'), warnIfMissed: false);
    await tester.pump();
  });
}
