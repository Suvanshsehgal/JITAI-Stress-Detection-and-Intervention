import 'package:flutter/material.dart';
import '../../shared/widgets/ebb_card.dart';

class ToolboxScreen extends StatelessWidget {
  const ToolboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toolbox')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: EbbCard(
            child: Center(
              child: Text(
                'Interventions Toolbox\n(Future Phase)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
