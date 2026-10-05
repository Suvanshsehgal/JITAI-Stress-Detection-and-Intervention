import 'package:flutter/material.dart';

import 'widgets/home_header.dart';
import 'widgets/health_snapshot.dart';
import 'widgets/suggested_action.dart';
import 'widgets/why_now.dart';
import 'widgets/mood_checkin.dart';
import 'widgets/baseline_progress.dart';
import 'widgets/sos_button.dart';
import '../../core/responsive/responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(context),
          tablet: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          HomeHeader(),
          HealthSnapshotWidget(),
          SizedBox(height: 32),
          SuggestedActionWidget(),
          SizedBox(height: 24),
          WhyNowWidget(),
          SizedBox(height: 32),
          MoodCheckInWidget(),
          SizedBox(height: 32),
          BaselineProgressWidget(),
          SizedBox(height: 48),
          SosButtonWidget(),
          SizedBox(height: 48), // Bottom padding for scrolling clearance
        ],
      ),
    );
  }
}
