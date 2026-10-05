import 'package:flutter/material.dart';
import '../../shared/widgets/ebb_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: EbbCard(
            child: Center(
              child: Text(
                'Stress & Health Insights\n(Future Phase)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
