import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class StillpointMascot extends StatelessWidget {
  final double size;

  const StillpointMascot({super.key, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(
        painter: _MascotPainter(),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Drop shadow ellipse at bottom
    final shadowPaint = Paint()
      ..color = const Color(0x22352520)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.95),
        width: w * 0.65,
        height: h * 0.1,
      ),
      shadowPaint,
    );

    // 2. Green Sprout on top
    final stemPaint = Paint()
      ..color = AppColors.mascotPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.3)
      ..quadraticBezierTo(w * 0.52, h * 0.15, w * 0.56, h * 0.08);
    canvas.drawPath(stemPath, stemPaint);

    final leafPaint = Paint()
      ..color = AppColors.mascotPurple
      ..style = PaintingStyle.fill;

    // Leaf 1
    final leaf1 = Path()
      ..moveTo(w * 0.56, h * 0.08)
      ..quadraticBezierTo(w * 0.72, h * 0.04, w * 0.75, h * 0.12)
      ..quadraticBezierTo(w * 0.65, h * 0.18, w * 0.56, h * 0.08);
    canvas.drawPath(leaf1, leafPaint);

    // Leaf 2
    final leaf2 = Path()
      ..moveTo(w * 0.51, h * 0.16)
      ..quadraticBezierTo(w * 0.38, h * 0.12, w * 0.35, h * 0.18)
      ..quadraticBezierTo(w * 0.44, h * 0.22, w * 0.51, h * 0.16);
    canvas.drawPath(leaf2, leafPaint);

    // 3. Cute feet
    final feetPaint = Paint()
      ..color = AppColors.mascotPurple
      ..style = PaintingStyle.fill;

    // Left foot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.78, w * 0.22, h * 0.14),
        Radius.circular(w * 0.07),
      ),
      feetPaint,
    );
    // Right foot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.50, h * 0.78, w * 0.22, h * 0.14),
        Radius.circular(w * 0.07),
      ),
      feetPaint,
    );

    // 4. Round Head & Ears / Cheeks
    final bodyPaint = Paint()
      ..color = AppColors.mascotPurple
      ..style = PaintingStyle.fill;

    // Ear bumps
    canvas.drawCircle(Offset(w * 0.18, h * 0.55), w * 0.10, bodyPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.55), w * 0.10, bodyPaint);

    // Main spherical head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.38, bodyPaint);

    // 5. Highlight on forehead
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.40, h * 0.35),
        width: w * 0.22,
        height: w * 0.12,
      ),
      highlightPaint,
    );

    // 6. Rosy Cheeks
    final cheekPaint = Paint()
      ..color = AppColors.mascotRosy
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.32, h * 0.55), width: w * 0.14, height: w * 0.09),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.68, h * 0.55), width: w * 0.14, height: w * 0.09),
      cheekPaint,
    );

    // 7. Happy Closed Arch Eyes
    final faceStroke = Paint()
      ..color = const Color(0xFF1E1120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    // Left eye arch
    final leftEye = Path()
      ..moveTo(w * 0.35, h * 0.47)
      ..quadraticBezierTo(w * 0.40, h * 0.41, w * 0.45, h * 0.47);
    canvas.drawPath(leftEye, faceStroke);

    // Right eye arch
    final rightEye = Path()
      ..moveTo(w * 0.55, h * 0.47)
      ..quadraticBezierTo(w * 0.60, h * 0.41, w * 0.65, h * 0.47);
    canvas.drawPath(rightEye, faceStroke);

    // 8. Sweet Smile Mouth
    final mouthPath = Path()
      ..moveTo(w * 0.43, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.63, w * 0.57, h * 0.56);
    canvas.drawPath(mouthPath, faceStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
