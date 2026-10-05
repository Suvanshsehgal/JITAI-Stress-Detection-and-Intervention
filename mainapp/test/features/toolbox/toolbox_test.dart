import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mainapp/features/toolbox/toolbox_screen.dart';
import 'package:mainapp/features/toolbox/history_screen.dart';
import 'package:mainapp/features/toolbox/providers/session_history_provider.dart';
import 'package:mainapp/features/toolbox/models/intervention_session.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject(Widget child) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('ToolboxScreen renders categories and interventions', (tester) async {
    await tester.pumpWidget(buildSubject(const ToolboxScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Toolbox'), findsOneWidget);
    expect(find.text('Calm Down'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    
    // Check for some interventions
    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('5-4-3-2-1 Grounding'), findsOneWidget);
  });

  testWidgets('HistoryScreen shows empty state initially', (tester) async {
    await tester.pumpWidget(buildSubject(const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Session History'), findsOneWidget);
    expect(find.text('No completed sessions yet.'), findsOneWidget);
  });

  testWidgets('HistoryProvider saves completed session and it appears on HistoryScreen', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]
    );

    final session = InterventionSession(
      id: 'session-123',
      interventionId: 'box-breathing',
      startedAt: DateTime(2023, 1, 1, 10, 0),
      completedAt: DateTime(2023, 1, 1, 10, 5),
      status: SessionStatus.completed,
      postMood: 'Great',
    );

    container.read(sessionHistoryProvider.notifier).saveSession(session);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
    expect(find.text('2023-01-01 10:00'), findsOneWidget);
  });
}
