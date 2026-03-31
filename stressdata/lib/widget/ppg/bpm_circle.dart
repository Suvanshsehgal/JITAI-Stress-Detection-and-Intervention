import 'package:flutter/material.dart';

class BpmCircle extends StatelessWidget {
  final int bpm;
  final Animation<double> heartBeatAnimation;
  final Animation<double> rippleAnimation1;
  final Animation<double> rippleAnimation2;
  final bool isAnimating;

  const BpmCircle({
    super.key,
    required this.bpm,
    required this.heartBeatAnimation,
    required this.rippleAnimation1,
    required this.rippleAnimation2,
    this.isAnimating = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple Ring 1 (only show when animating)
          if (isAnimating)
            AnimatedBuilder(
              animation: rippleAnimation1,
              builder: (context, child) {
                return Container(
                  width: 220 * rippleAnimation1.value,
                  height: 220 * rippleAnimation1.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD97B6C).withValues(alpha: 1 - rippleAnimation1.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // Ripple Ring 2 (only show when animating)
          if (isAnimating)
            AnimatedBuilder(
              animation: rippleAnimation2,
              builder: (context, child) {
                return Container(
                  width: 220 * rippleAnimation2.value,
                  height: 220 * rippleAnimation2.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD97B6C).withValues(alpha: 1 - rippleAnimation2.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // White inner circle with BPM info only
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated heart icon (only animate when isAnimating is true)
                if (isAnimating)
                  ScaleTransition(
                    scale: heartBeatAnimation,
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFF9B2B1A),
                      size: 40,
                    ),
                  )
                else
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFF9B2B1A),
                    size: 40,
                  ),
                const SizedBox(height: 8),
                // BPM value
                Text(
                  '$bpm',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A08),
                  ),
                ),
                const SizedBox(height: 4),
                // BPM label
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD97B6C),
                    letterSpacing: 2,
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
