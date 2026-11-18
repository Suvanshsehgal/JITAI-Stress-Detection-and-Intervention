import 'package:flutter/material.dart';
import 'widgets/home_header.dart';
import 'widgets/health_snapshot.dart';
import 'widgets/watch_banner.dart';
import 'widgets/suggested_action.dart';
import 'widgets/quick_access_row.dart';
import 'widgets/this_week_card.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          HomeHeader(),
          HealthSnapshotWidget(),
          SizedBox(height: 12),
          WatchBannerWidget(),
          SizedBox(height: 16),
          SuggestedActionWidget(),
          SizedBox(height: 16),
          QuickAccessRow(),
          SizedBox(height: 16),
          ThisWeekCard(),
          SizedBox(height: 90), // Bottom clearance for floating nav bar
        ],
      ),
    );
  }
}
