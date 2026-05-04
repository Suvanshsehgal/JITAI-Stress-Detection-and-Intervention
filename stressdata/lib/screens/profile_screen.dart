import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'onboarding.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _email = '';
  bool _isLoading = true;
  List<_SessionResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final email = user.email ?? '';
    _email = email;
    _userName = email.isNotEmpty ? email.split('@').first.capitalize() : 'User';

    try {
      // Fetch all completed sessions, newest first
      final sessions = await SupabaseConfig.client
          .from('test_sessions')
          .select('id, start_time')
          .eq('user_id', user.id)
          .not('end_time', 'is', null)
          .order('start_time', ascending: false);

      final List<_SessionResult> results = [];

      for (final s in sessions as List) {
        final sid = s['id'] as String;
        final date = DateTime.parse(s['start_time'] as String);

        // Fetch stress score
        Map<String, dynamic>? stress;
        try {
          stress = await SupabaseConfig.client
              .from('stress_scores')
              .select('stress_score, stress_label_binary')
              .eq('session_id', sid)
              .maybeSingle();
        } catch (_) {}

        // Fetch cognitive metrics
        Map<String, dynamic>? cog;
        try {
          cog = await SupabaseConfig.client
              .from('cognitive_metrics')
              .select(
                  'stroop_accuracy, speed_accuracy, memory_accuracy, avg_response_time, stroop_avg_response_time')
              .eq('session_id', sid)
              .maybeSingle();
        } catch (_) {}

        // Fetch physiological metrics
        Map<String, dynamic>? physio;
        try {
          physio = await SupabaseConfig.client
              .from('physiological_metrics')
              .select('heart_rate_avg, rmssd')
              .eq('session_id', sid)
              .maybeSingle();
        } catch (_) {}

        results.add(_SessionResult(
          date: date,
          stressScore: (stress?['stress_score'] as num?)?.toDouble(),
          stressLabel: stress?['stress_label_binary'] as int?,
          stroopAccuracy: (cog?['stroop_accuracy'] as num?)?.toDouble(),
          speedAccuracy: (cog?['speed_accuracy'] as num?)?.toDouble(),
          memoryAccuracy: (cog?['memory_accuracy'] as num?)?.toDouble(),
          heartRate: (physio?['heart_rate_avg'] as num?)?.toDouble(),
          rmssd: (physio?['rmssd'] as num?)?.toDouble(),
        ));
      }

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Profile load error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F4),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4B3425)),
            )
          : RefreshIndicator(
              color: const Color(0xFF4B3425),
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4B3425),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA9B7E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 3),
                            ),
                            child: Center(
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userName.isNotEmpty ? _userName : 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Summary pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              '${_results.length} test${_results.length == 1 ? '' : 's'} completed',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Section title ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                      child: Text(
                        _results.isEmpty ? '' : 'Test History',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A0A08),
                        ),
                      ),
                    ),
                  ),

                  // ── Results list or empty state ──────────────────────
                  _results.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ResultCard(
                                  result: _results[i],
                                  index: i,
                                ),
                              ),
                              childCount: _results.length,
                            ),
                          ),
                        ),

                  // ── Logout ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined,
                size: 72,
                color: const Color(0xFF4B3425).withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            const Text(
              'No tests yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0A08),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first test to see results here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1A0A08).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(
                color: Color(0xFF1A0A08), fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF1A0A08))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Result card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _SessionResult result;
  final int index;

  const _ResultCard({required this.result, required this.index});

  @override
  Widget build(BuildContext context) {
    final scoreInt = result.stressScore != null
        ? (result.stressScore! * 100).round()
        : null;
    final isStressed = result.stressLabel == 1;
    final statusColor = _scoreColor(scoreInt, isStressed);
    final statusLabel = _scoreLabel(scoreInt, isStressed);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: index == 0
            ? Border.all(color: const Color(0xFF4B3425), width: 1.5)
            : null,
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
          // ── Card header ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Date + latest badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B3425),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LATEST',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 13,
                              color: const Color(0xFF1A0A08)
                                  .withValues(alpha: 0.45)),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(result.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF1A0A08)
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stress badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Stress score row ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _BigMetric(
                  label: 'Stress Score',
                  value: scoreInt != null ? '$scoreInt' : '—',
                  unit: scoreInt != null ? '/100' : '',
                  color: statusColor,
                ),
                if (result.heartRate != null) ...[
                  const SizedBox(width: 24),
                  _BigMetric(
                    label: 'Heart Rate',
                    value: result.heartRate!.round().toString(),
                    unit: 'bpm',
                    color: const Color(0xFFD64933),
                  ),
                ],
                if (result.rmssd != null) ...[
                  const SizedBox(width: 24),
                  _BigMetric(
                    label: 'HRV (RMSSD)',
                    value: result.rmssd!.round().toString(),
                    unit: 'ms',
                    color: const Color(0xFF2E7D5F),
                  ),
                ],
              ],
            ),
          ),

          // ── Cognitive bars ───────────────────────────────────────
          if (result.stroopAccuracy != null ||
              result.speedAccuracy != null ||
              result.memoryAccuracy != null) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Text(
                'COGNITIVE PERFORMANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9B8070),
                  letterSpacing: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Row(
                children: [
                  if (result.stroopAccuracy != null)
                    Expanded(
                      child: _AccuracyBar(
                        label: 'Stroop',
                        value: result.stroopAccuracy!,
                        color: const Color(0xFFD64933),
                      ),
                    ),
                  if (result.stroopAccuracy != null &&
                      (result.speedAccuracy != null ||
                          result.memoryAccuracy != null))
                    const SizedBox(width: 12),
                  if (result.speedAccuracy != null)
                    Expanded(
                      child: _AccuracyBar(
                        label: 'Speed',
                        value: result.speedAccuracy!,
                        color: const Color(0xFF2E7D5F),
                      ),
                    ),
                  if (result.speedAccuracy != null &&
                      result.memoryAccuracy != null)
                    const SizedBox(width: 12),
                  if (result.memoryAccuracy != null)
                    Expanded(
                      child: _AccuracyBar(
                        label: 'Memory',
                        value: result.memoryAccuracy!,
                        color: const Color(0xFFE8A547),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 18),
        ],
      ),
    );
  }

  Color _scoreColor(int? score, bool isStressed) {
    if (score == null) return const Color(0xFF999999);
    if (isStressed || score < 40) return const Color(0xFFD64933);
    if (score < 60) return const Color(0xFFEA9B7E);
    if (score < 80) return const Color(0xFFE8A547);
    return const Color(0xFF2E7D5F);
  }

  String _scoreLabel(int? score, bool isStressed) {
    if (score == null) return 'PENDING';
    if (isStressed) return 'STRESSED';
    if (score >= 80) return 'EXCELLENT';
    if (score >= 60) return 'GOOD';
    if (score >= 40) return 'FAIR';
    return 'HIGH STRESS';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m $period';
  }
}

// ─── Big metric widget ────────────────────────────────────────────────────────

class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _BigMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9B8070),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Accuracy bar widget ──────────────────────────────────────────────────────

class _AccuracyBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final Color color;

  const _AccuracyBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9B8070),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _SessionResult {
  final DateTime date;
  final double? stressScore;
  final int? stressLabel;
  final double? stroopAccuracy;
  final double? speedAccuracy;
  final double? memoryAccuracy;
  final double? heartRate;
  final double? rmssd;

  const _SessionResult({
    required this.date,
    this.stressScore,
    this.stressLabel,
    this.stroopAccuracy,
    this.speedAccuracy,
    this.memoryAccuracy,
    this.heartRate,
    this.rmssd,
  });
}

// ─── String extension ─────────────────────────────────────────────────────────

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
