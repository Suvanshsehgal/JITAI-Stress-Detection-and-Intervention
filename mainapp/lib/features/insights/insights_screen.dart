import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
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
