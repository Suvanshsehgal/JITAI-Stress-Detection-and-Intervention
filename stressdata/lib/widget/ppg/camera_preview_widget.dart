import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD97B6C),
              width: 3,
            ),
            color: const Color(0xFF1A0A08),
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Color(0xFFD97B6C),
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Place finger on camera & flash',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF1A0A08),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
