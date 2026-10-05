import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mainapp/features/interventions/screens/intervention_detail_screen.dart';
import 'package:mainapp/features/interventions/screens/intervention_completion_screen.dart';
import 'package:mainapp/features/interventions/runners/step_runner.dart';
import 'package:go_router/go_router.dart';
import 'package:mainapp/features/toolbox/models/intervention.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject(Widget child) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: '/intervention/:id/complete',
          builder: (context, state) => const Scaffold(body: Text('Completed Dummy')),
        ),
        GoRoute(
          path: '/intervention/:id/run',
          builder: (context, state) => const Scaffold(body: Text('Run Dummy')),
        ),
        GoRoute(
          path: '/toolbox',
          builder: (context, state) => const Scaffold(body: Text('Toolbox Dummy')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('InterventionDetailScreen renders details and instructions', (tester) async {
    await tester.pumpWidget(buildSubject(
      const InterventionDetailScreen(interventionId: 'box-breathing')
    ));
    await tester.pumpAndSettle();

    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('Purpose'), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);
    expect(find.text('Inhale deeply for 4 seconds.'), findsOneWidget);
  });

  testWidgets('StepRunner progresses through steps', (tester) async {
    const dummyIntervention = Intervention(
      id: 'test',
      title: 'Test Step',
      description: 'Test desc',
      category: InterventionCategory.reset,
      duration: '1 min',
      difficulty: 'Easy',
      icon: 'icon',
      instructions: ['Step 1', 'Step 2'],
      type: InterventionType.stepGuided,
    );

    await tester.pumpWidget(buildSubject(
      const StepRunner(intervention: dummyIntervention)
    ));
    await tester.pumpAndSettle();

    // Initial state
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Step 1'), findsOneWidget);

    // Tap next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Second state
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Step 2'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    
    // Tap previous
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    
    // Back to first
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('CompletionScreen renders moods and finishes', (tester) async {
    await tester.pumpWidget(buildSubject(
      InterventionCompletionScreen(
        interventionId: 'test',
        startedAt: DateTime.now(),
      )
    ));
    await tester.pumpAndSettle();

    expect(find.text('Great job.'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);

    // Select mood
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();

    // Tap Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });
}
