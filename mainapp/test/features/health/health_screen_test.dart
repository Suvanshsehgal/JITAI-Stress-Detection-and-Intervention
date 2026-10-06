import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';
import 'package:mainapp/features/health/health_screen.dart';
import 'package:mainapp/features/health/widgets/data_source_status_card.dart';
import 'package:mainapp/features/settings/settings_screen.dart';
import 'package:mainapp/features/home/widgets/health_snapshot.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboardingDataPrefs': ['hr_hrv', 'sleep'],
      'buddyName': 'Pip',
      'buddyTone': 'gentle',
    });
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

  testWidgets('HealthScreen renders all 5 sources and context summary', (tester) async {
    await tester.pumpWidget(buildSubject(const HealthScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Health & Context Data'), findsOneWidget);
    expect(find.text('Contextual Signals'), findsOneWidget);
    expect(find.text('Context Snapshot'), findsOneWidget);

    // Verify all 5 sources are present in DataSourceStatusCard
    expect(find.descendant(of: find.byType(DataSourceStatusCard), matching: find.text('Heart Rate')), findsOneWidget);
    expect(find.descendant(of: find.byType(DataSourceStatusCard), matching: find.text('Heart Rate Variability')), findsOneWidget);
    expect(find.descendant(of: find.byType(DataSourceStatusCard), matching: find.text('Sleep')), findsOneWidget);
    expect(find.descendant(of: find.byType(DataSourceStatusCard), matching: find.text('Calendar (Busy/Free)')), findsOneWidget);
    expect(find.descendant(of: find.byType(DataSourceStatusCard), matching: find.text('Notifications')), findsOneWidget);

    expect(find.byType(DataSourceStatusCard), findsNWidgets(5));
  });

  testWidgets('Toggling source in HealthScreen updates preference', (tester) async {
    await tester.pumpWidget(buildSubject(const HealthScreen()));
    await tester.pumpAndSettle();

    // Calendar is initially disabled (off)
    final calendarCard = find.ancestor(
      of: find.text('Calendar (Busy/Free)'),
      matching: find.byType(DataSourceStatusCard),
    );
    expect(calendarCard, findsOneWidget);

    final calendarSwitch = find.descendant(
      of: calendarCard,
      matching: find.byType(Switch),
    );
    expect(calendarSwitch, findsOneWidget);

    // Toggle switch
    await tester.ensureVisible(calendarSwitch);
    await tester.pumpAndSettle();
    await tester.tap(calendarSwitch);
    await tester.pumpAndSettle();

    // Verify preference is updated in SharedPreferences
    final updatedPrefs = prefs.getStringList('onboardingDataPrefs') ?? [];
    expect(updatedPrefs.contains('calendar'), isTrue);
  });

  testWidgets('Granting permission updates status and shows SnackBar', (tester) async {
    await tester.pumpWidget(buildSubject(const HealthScreen()));
    await tester.pumpAndSettle();

    // Heart Rate is enabled in prefs, but permission is required
    final grantButton = find.widgetWithText(OutlinedButton, 'Grant Permission').first;
    expect(grantButton, findsOneWidget);

    await tester.ensureVisible(grantButton);
    await tester.pumpAndSettle();
    await tester.tap(grantButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Permission granted for'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays Health & Context Signals item and info', (tester) async {
    await tester.pumpWidget(buildSubject(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Health & Context Signals'), findsOneWidget);
    expect(find.text('Buddy Preferences'), findsOneWidget);
    expect(find.text('Baseline Status'), findsOneWidget);
    expect(find.text('About Ebb'), findsOneWidget);
  });

  testWidgets('HealthSnapshotWidget renders Disabled when source preference is disabled', (tester) async {
    // Both hr_hrv and sleep disabled
    SharedPreferences.setMockInitialValues({
      'onboardingDataPrefs': <String>[],
    });
    final customPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(customPrefs),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HealthSnapshotWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Since hr_hrv is disabled, HR and HRV should show 'Disabled'
    expect(find.text('Disabled'), findsWidgets);
  });
}
