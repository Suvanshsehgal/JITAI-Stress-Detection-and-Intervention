import 'package:flutter/material.dart';
import 'dart:math';

class PPGWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color waveColor;
  final double strokeWidth;

  PPGWaveformPainter({
    required this.waveformData,
    this.waveColor = const Color(0xFF9B2B1A),
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    // Normalize data to fit canvas
    final minValue = waveformData.reduce(min);
    final maxValue = waveformData.reduce(max);
    final range = maxValue - minValue;
    
    if (range == 0) return;

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (waveformData.length - 1);

    for (int i = 0; i < waveformData.length; i++) {
      final normalizedValue = (waveformData[i] - minValue) / range;
      final x = i * stepX;
      final y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw baseline
    final baselinePaint = Paint()
      ..color = waveColor.withOpacity(0.2)
      ..strokeWidth = 1.0;
    
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      baselinePaint,
    );
  }

  @override
  bool shouldRepaint(PPGWaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData;
  }
}
