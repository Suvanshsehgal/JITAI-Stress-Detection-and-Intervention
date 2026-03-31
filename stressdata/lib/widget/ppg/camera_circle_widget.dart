import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraCircleWidget extends StatelessWidget {
  final CameraController? cameraController;

  const CameraCircleWidget({
    super.key,
    this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD97B6C),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: cameraController != null && cameraController!.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.previewSize!.height,
                  height: cameraController!.value.previewSize!.width,
                  child: CameraPreview(cameraController!),
                ),
              )
            : Container(
                color: const Color(0xFF1A0A08),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFFD97B6C),
                  size: 40,
                ),
              ),
      ),
    );
  }
}
