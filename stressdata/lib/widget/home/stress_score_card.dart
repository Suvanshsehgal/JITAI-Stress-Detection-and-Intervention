import 'package:flutter/material.dart';
import '../../screens/test_map_screen.dart';

class StressScoreCard extends StatelessWidget {
  /// Score as 0–100 integer. Null means no score available yet.
  final int? score;

  /// 0 = not stressed, 1 = stressed. Null if not available.
  final int? stressLabel;

  const StressScoreCard({
    super.key,
    required this.score,
    required this.stressLabel,
  });

  String get _statusMessage {
    if (score == null) return 'No data yet';
    if (stressLabel == 1) return 'You may be experiencing stress';
    if (score! >= 70) return 'You are mentally healthy';
    if (score! >= 40) return 'Moderate stress detected';
    return 'High stress detected';
  }

  Color get _progressColor {
    if (score == null) return Colors.white54;
    if (stressLabel == 1 || score! < 40) return const Color(0xFFEF5350);
    if (score! < 70) return const Color(0xFFFFB74D);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final displayScore = score ?? 0;
    final progressValue = displayScore / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4A35),
            Color(0xFF4B3425),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B3425).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    score == null
                        ? const Icon(Icons.hourglass_empty,
                            color: Colors.white54, size: 40)
                        : Text(
                            '$displayScore',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    Text(
                      'SCORE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Stress Score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestMapScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4B3425),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
    );
  }
}
