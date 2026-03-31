import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isFlashOn = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isFlashOn => _isFlashOn;

  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      // Use back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  Future<void> turnOnFlash() async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.setFlashMode(FlashMode.torch);
        _isFlashOn = true;
      } catch (e) {
        debugPrint('Flash on error: $e');
      }
    }
  }

  Future<void> turnOffFlash() async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      } catch (e) {
        debugPrint('Flash off error: $e');
      }
    }
  }

  void startImageStream(Function(CameraImage) onImage) {
    if (_controller != null && _isInitialized) {
      _controller!.startImageStream(onImage);
    }
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Stop image stream error: $e');
      }
    }
  }

  Future<void> dispose() async {
    await stopImageStream();
    await turnOffFlash();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
