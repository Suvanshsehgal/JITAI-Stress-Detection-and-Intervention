import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/colors.dart';
import '../widget/home/greeting_header.dart';
import '../widget/home/stress_score_card.dart';
import '../widget/home/mood_section.dart';
import '../widget/home/weekly_insights_card.dart';
import '../widget/home/recommendation_card.dart';
import '../widget/bottom_nav_bar.dart';
import '../services/database_service.dart';
import 'test_screen.dart';
import 'profile_screen.dart';
import 'test_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasCompletedTest = false;
  bool _isLoading = true;
  double? _latestStressScore;
  int? _latestStressLabel;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkUserTestStatus();
  }

  Future<void> _checkUserTestStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        debugPrint('❌ No user logged in');
        setState(() {
          _hasCompletedTest = false;
          _isLoading = false;
        });
        return;
      }

      final userId = user.id;

      // Check if user has any completed session
      final latestSession = await _dbService.getLatestSession(userId);

      // Fetch the latest stress score directly (ordered by computed_at)
      // This avoids the case where a session exists but has no score yet
      double? stressScore;
      int? stressLabel;
      try {
        final scoreRow = await _dbService.getLatestStressScore(userId);
        if (scoreRow != null) {
          stressScore = (scoreRow['stress_score'] as num?)?.toDouble();
          stressLabel = scoreRow['stress_label_binary'] as int?;
          debugPrint('✅ Latest stress score: $stressScore, label: $stressLabel');
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch stress score: $e');
      }

      setState(() {
        _hasCompletedTest = latestSession != null;
        _latestStressScore = stressScore;
        _latestStressLabel = stressLabel;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to check user test status: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      setState(() {
        _hasCompletedTest = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9B2B1A),
          ),
        ),
      );
    }

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
              IndexedStack(
                index: _currentIndex,
                children: [
                  _HomeContent(
                    hasCompletedTest: _hasCompletedTest,
                    stressScore: _latestStressScore,
                    stressLabel: _latestStressLabel,
                    onStartTest: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestMapScreen(),
                        ),
                      ).then((_) {
                        debugPrint('🔄 Refreshing test status after test completion');
                        _checkUserTestStatus();
                      });
                    },
                  ),
                  const TestScreen(),
                  const ProfileScreen(),
                ],
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

class _HomeContent extends StatelessWidget {
  final bool hasCompletedTest;
  final double? stressScore;
  final int? stressLabel;
  final VoidCallback onStartTest;

  const _HomeContent({
    required this.hasCompletedTest,
    required this.stressScore,
    required this.stressLabel,
    required this.onStartTest,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCompletedTest) {
      return _buildFirstTestScreen(context);
    }

    // Convert 0.0–1.0 score to 0–100 display value
    final displayScore = stressScore != null
        ? (stressScore! * 100).round()
        : null;

    return SingleChildScrollView(
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
          StressScoreCard(
            score: displayScore,
            stressLabel: stressLabel,
          ),
          const SizedBox(height: 24),
          const MoodSection(
            sleepHours: 0,
            steps: 0,
          ),
          const SizedBox(height: 24),
          const WeeklyInsightsCard(),
          const SizedBox(height: 24),
          const RecommendationCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFirstTestScreen(BuildContext context) {
    return SingleChildScrollView(
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
          const SizedBox(height: 40),

          // Welcome Message
          Text(
            'Welcome to Your\nStress Journey',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start your first comprehensive stress assessment to get personalized insights and recommendations.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          // Main CTA Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                Color(0xFF4E342E), // dark chocolate brown
                Color(0xFF8D6E63), // medium warm brown
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B2B1A).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Start Your First Test',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Complete a comprehensive assessment including heart rate measurement, questionnaires, and cognitive tests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onStartTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF9B2B1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Begin Assessment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // What to Expect Section
          Text(
            'What to Expect',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          _buildExpectationCard(
            icon: Icons.timer,
            title: '~15 Minutes',
            description: 'Complete assessment at your own pace',
          ),
          const SizedBox(height: 12),

          _buildExpectationCard(
            icon: Icons.favorite,
            title: 'Heart Rate Monitoring',
            description: 'Measure your physiological stress response',
          ),
          const SizedBox(height: 12),

          _buildExpectationCard(
            icon: Icons.quiz,
            title: 'Interactive Tests',
            description: 'Engaging cognitive and psychological assessments',
          ),
          const SizedBox(height: 12),

          _buildExpectationCard(
            icon: Icons.insights,
            title: 'Personalized Insights',
            description: 'Get detailed analysis and recommendations',
          ),

          const SizedBox(height: 32),

          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your data is private and secure. We never share your personal information.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectationCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}