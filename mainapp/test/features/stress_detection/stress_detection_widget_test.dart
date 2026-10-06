import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mainapp/core/providers/shared_prefs_provider.dart';
import 'package:mainapp/features/health/models/context_snapshot.dart';
import 'package:mainapp/features/health/models/heart_rate_sample.dart';
import 'package:mainapp/features/health/models/hrv_sample.dart';
import 'package:mainapp/features/health/providers/health_providers.dart';
import 'package:mainapp/features/stress_detection/models/inference_status.dart';
import 'package:mainapp/features/stress_detection/providers/stress_detection_providers.dart';
import 'package:mainapp/features/stress_detection/services/mock_stress_detection_service.dart';
import 'package:mainapp/features/stress_detection/widgets/stress_assessment_card.dart';

void main() {
  late SharedPreferences prefs;
  late MockStressDetectionService mockService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockService = MockStressDetectionService();
  });

  Widget buildSubject({
    ContextSnapshot? snapshotOverride,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        stressDetectionServiceProvider.overrideWithValue(mockService),
        if (snapshotOverride != null)
          contextSnapshotProvider
              .overrideWith((ref) => Future.value(snapshotOverride)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StressAssessmentCard(),
          ),
        ),
      ),
    );
  }

  group('StressDetectionNotifier and Widget', () {
    testWidgets('StressAssessmentCard renders initial state and button',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Pattern Assessment'), findsOneWidget);
      expect(find.text('Assess Current State'), findsOneWidget);
    });

    testWidgets('Tapping Assess Current State renders insufficientData when signals absent',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        snapshotOverride: ContextSnapshot.empty(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assess Current State'));
      await tester.pumpAndSettle();

      // Non-alarming state shown
      expect(find.text('More Information Needed'), findsOneWidget);
      expect(find.textContaining('Keep checking in daily'), findsOneWidget);
      expect(find.text('Re-evaluate Signals'), findsOneWidget);
    });

    testWidgets('Tapping Assess Current State renders success state when signals present',
        (tester) async {
      final now = DateTime.now();
      final populatedSnapshot = ContextSnapshot(
        timestamp: now,
        heartRate: HeartRateSample(bpm: 70.0, timestamp: now),
        hrv: HRVSample(rmssdMs: 44.0, timestamp: now),
      );

      await tester.pumpWidget(buildSubject(
        snapshotOverride: populatedSnapshot,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assess Current State'));
      await tester.pumpAndSettle();

      expect(find.text('Steady'), findsOneWidget);
      expect(find.textContaining('confidence'), findsOneWidget);
      expect(find.text('Re-evaluate Signals'), findsOneWidget);
    });

    testWidgets('StressAssessmentCard displays error state gracefully',
        (tester) async {
      mockService.forcedStatus = InferenceStatus.error;

      await tester.pumpWidget(buildSubject(
        snapshotOverride: ContextSnapshot.empty(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assess Current State'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to Assess'), findsOneWidget);
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    test('StressDetectionNotifier prevents duplicate concurrent requests',
        () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          stressDetectionServiceProvider.overrideWithValue(mockService),
          contextSnapshotProvider.overrideWith((ref) async {
            // Simulate slight delay in context retrieval
            await Future.delayed(const Duration(milliseconds: 50));
            return ContextSnapshot.empty();
          }),
        ],
      );

      final notifier = container.read(stressDetectionProvider.notifier);

      // Launch first request
      final firstFuture = notifier.assessCurrentState();
      expect(container.read(stressDetectionProvider).isLoading, isTrue);

      // Concurrent second request should be rejected (returns null immediately)
      final secondResult = await notifier.assessCurrentState();
      expect(secondResult, isNull);

      final firstResult = await firstFuture;
      expect(firstResult, isNotNull);
      expect(container.read(stressDetectionProvider).isLoading, isFalse);
    });
  });
}
