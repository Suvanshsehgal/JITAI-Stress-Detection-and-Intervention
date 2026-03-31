import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../widget/home/greeting_header.dart';
import '../widget/home/stress_score_card.dart';
import '../widget/home/mood_section.dart';
import '../widget/home/weekly_insights_card.dart';
import '../widget/home/recommendation_card.dart';
import '../widget/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const GreetingHeader(name: 'Suvansh'),
                    const SizedBox(height: 24),
                    const StressScoreCard(score: 88),
                    const SizedBox(height: 24),
                    const MoodSection(
                      sleepHours: 8.2,
                      steps: 6.4,
                    ),
                    const SizedBox(height: 24),
                    const WeeklyInsightsCard(),
                    const SizedBox(height: 24),
                    const RecommendationCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}