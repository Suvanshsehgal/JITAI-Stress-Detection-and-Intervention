import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mainapp/features/insights/insights_screen.dart';
import 'package:mainapp/features/insights/providers/mood_provider.dart';
import 'package:mainapp/features/insights/models/mood_entry.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject(Widget child, ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('InsightsScreen renders empty state', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]
    );

    await tester.pumpWidget(buildSubject(const InsightsScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Baseline Learning'), findsOneWidget);
    expect(find.text('Weekly Overview'), findsOneWidget);
    expect(find.text('Toolbox Usage'), findsOneWidget);
    expect(find.textContaining('Welcome to Ebb'), findsOneWidget);
    expect(find.textContaining('haven\'t completed any toolbox sessions'), findsOneWidget);
  });

  testWidgets('InsightsScreen renders populated state correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]
    );

    container.read(moodProvider.notifier).addMood(
      MoodEntry(id: '1', moodValue: 4, timestamp: DateTime.now())
    );

    // Provide a mock session by writing to prefs directly or mocking the provider
    SharedPreferences.setMockInitialValues({
      'intervention_history': [
        '{"id":"s1","interventionId":"box-breathing","startedAt":"2023-01-01T10:00:00.000","completedAt":"2023-01-01T10:05:00.000","status":"completed","postMood":"Great"}'
      ]
    });
    
    // Create new prefs instance after setting mock values
    final populatedPrefs = await SharedPreferences.getInstance();
    final populatedContainer = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(populatedPrefs),
      ]
    );

    populatedContainer.read(moodProvider.notifier).addMood(
      MoodEntry(id: '1', moodValue: 4, timestamp: DateTime.now())
    );

    await tester.pumpWidget(buildSubject(const InsightsScreen(), populatedContainer));
    await tester.pumpAndSettle();

    expect(find.text('Total Completed: 1'), findsOneWidget);
    expect(find.text('Most Frequent: Box Breathing'), findsOneWidget);
  });
}
