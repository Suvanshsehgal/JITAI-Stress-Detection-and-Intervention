import 'package:flutter/material.dart';
import '../../shared/widgets/ebb_card.dart';

class BuddyScreen extends StatelessWidget {
  const BuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buddy')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: EbbCard(
            child: Center(
              child: Text(
                'Buddy Chatbot Interface\n(Future Phase)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
