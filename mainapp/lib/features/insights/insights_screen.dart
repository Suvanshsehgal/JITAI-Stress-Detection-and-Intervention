import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stress_detection/widgets/stress_assessment_card.dart';
import 'widgets/baseline_progress_card.dart';
import 'widgets/intervention_usage_card.dart';
import 'widgets/mood_chart.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              StressAssessmentCard(),
              SizedBox(height: 16),
              BaselineProgressCard(),
              SizedBox(height: 16),
              MoodChartCard(),
              SizedBox(height: 16),
              InterventionUsageCard(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
