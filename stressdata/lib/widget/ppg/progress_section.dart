import 'package:flutter/material.dart';

class ProgressSection extends StatelessWidget {
  final Animation<double> progressAnimation;

  const ProgressSection({
    super.key,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, child) {
        final percentage = (progressAnimation.value * 100).toInt();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MEASUREMENT PROGRESS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A0A08),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97B6C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressAnimation.value,
                minHeight: 8,
                backgroundColor: const Color(0xFFE8D5CE),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97B6C)),
              ),
            ),
          ],
        );
      },
    );
  }
}
