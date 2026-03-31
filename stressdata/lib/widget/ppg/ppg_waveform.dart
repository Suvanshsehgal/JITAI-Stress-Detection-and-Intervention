import 'package:flutter/material.dart';
import 'dart:math';

class PpgWaveform extends StatelessWidget {
  final Animation<double> waveAnimation;

  const PpgWaveform({
    super.key,
    required this.waveAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: waveAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                offset: waveAnimation.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double offset;

  WavePainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD97B6C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveLength = 80.0; // Fixed wavelength for consistent waves
    final amplitude = size.height * 0.35;
    final centerY = size.height / 2;

    // Calculate the horizontal offset based on animation
    final horizontalOffset = offset * waveLength;

    // Start drawing from before the visible area
    final startX = -waveLength - horizontalOffset;
    
    // Draw the wave path
    for (double x = startX; x <= size.width + waveLength; x += 1) {
      final normalizedX = x + horizontalOffset;
      final y = centerY + amplitude * sin((normalizedX / waveLength) * 2 * pi);
      
      if (x == startX) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}
