import 'package:flutter/material.dart';
import '../../shared/widgets/ebb_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: EbbCard(
            child: Center(
              child: Text(
                'User Profile & Settings\n(Future Phase)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
