// lib/widget/home/weekly_insights_card.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyInsightsCard extends StatefulWidget {
  const WeeklyInsightsCard({super.key});

  @override
  State<WeeklyInsightsCard> createState() => _WeeklyInsightsCardState();
}

class _WeeklyInsightsCardState extends State<WeeklyInsightsCard> {
  // Map of "YYYY-MM-DD" → score (0–100)
  Map<String, int> _weekScores = {};
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchAndSubscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchAndSubscribe() async {
    await _fetchWeekScores();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Real-time: listen for new rows in stress_scores for this user
    _channel = Supabase.instance.client
        .channel('weekly_insights_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'stress_scores',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _fetchWeekScores(),
        )
        .subscribe();
  }

  Future<void> _fetchWeekScores() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final from = DateTime(
        sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    try {
      final rows = await Supabase.instance.client
          .from('stress_scores')
          .select('stress_score, computed_at')
          .eq('user_id', userId)
          .gte('computed_at', from.toIso8601String())
          .order('computed_at', ascending: true);

      // Group by date — keep the latest score per day
      final Map<String, int> scores = {};
      for (final row in rows as List) {
        final dt =
            DateTime.parse(row['computed_at'] as String).toLocal();
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        final score = ((row['stress_score'] as num) * 100).round();
        scores[key] = score; // later entries overwrite earlier ones (latest wins)
      }

      if (mounted) {
        setState(() {
          _weekScores = scores;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ WeeklyInsightsCard fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Build the ordered list of the last 7 days (oldest → newest)
  List<_DayPoint> _buildDayPoints() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return _DayPoint(
        label: _shortDay(day.weekday),
        score: _weekScores[key], // null = no test that day
      );
    });
  }

  String _shortDay(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Color _barColor(int score) {
    if (score <= 40) return const Color(0xFF4CAF50); // green  — low stress
    if (score <= 70) return const Color(0xFFFFC107); // yellow — medium
    return const Color(0xFFE53935); // red    — high
  }

  String _insightText(List<_DayPoint> points) {
    final scored = points.where((p) => p.score != null).toList();
    if (scored.isEmpty) return 'No tests recorded this week yet.';
    if (scored.length == 1) return 'Only one test this week — keep it up!';

    final scores = scored.map((p) => p.score!).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final first = scores.first;
    final last = scores.last;
    final diff = last - first;
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxDay = scored[scores.indexOf(maxScore)].label;

    if (diff <= -10) {
      return 'Great progress! Your stress dropped by ${diff.abs()} points this week 🎉';
    } else if (diff >= 10) {
      return 'Stress rose by $diff points this week. Try some breathing exercises 🧘';
    } else if (avg <= 40) {
      return 'You had a calm week overall. Keep it up! 🌿';
    } else if (avg > 70) {
      return 'High stress week. Consider taking breaks and resting more 💙';
    } else {
      return 'Stress peaked on $maxDay. Mid-week pressure is common — you\'re doing fine.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B3425).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF4B3425),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Stress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A08),
                ),
              ),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF4B3425).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          if (_isLoading)
            const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF9B2B1A),
                ),
              ),
            )
          else
            _buildBarChart(),

          const SizedBox(height: 16),

          // Insight text
          if (!_isLoading) _buildInsightBanner(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final points = _buildDayPoints();
    const chartHeight = 80.0;

    return SizedBox(
      height: chartHeight + 24, // bars + day labels
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final hasScore = p.score != null;
          final barFraction = hasScore ? p.score! / 100.0 : 0.0;
          final barH = (barFraction * chartHeight).clamp(4.0, chartHeight);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Score label above bar
                  if (hasScore)
                    Text(
                      '${p.score}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B3425),
                      ),
                    )
                  else
                    const SizedBox(height: 12),

                  const SizedBox(height: 2),

                  // Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: hasScore ? barH : 4,
                    decoration: BoxDecoration(
                      color: hasScore
                          ? _barColor(p.score!)
                          : const Color(0xFF4B3425).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Day label
                  Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF4B3425).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightBanner() {
    final points = _buildDayPoints();
    final text = _insightText(points);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4B3425).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B3425),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPoint {
  final String label;
  final int? score; // null = no test that day

  const _DayPoint({required this.label, required this.score});
}
