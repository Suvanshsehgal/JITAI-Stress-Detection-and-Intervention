import 'package:camera/camera.dart';
import 'dart:math';

class PpgProcessor {
  final List<double> _redValues = [];
  final List<int> _timestamps = [];
  final int _windowSize = 50; // Number of samples to keep
  final int _minSamples = 30; // Minimum samples before calculating BPM

  int _currentBpm = 0;
  String _signalQuality = 'Place finger';
  bool _isProcessing = false;

  int get currentBpm => _currentBpm;
  String get signalQuality => _signalQuality;

  void processFrame(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Extract average red intensity
      final redIntensity = _extractRedIntensity(image);
      
      if (redIntensity > 0) {
        _redValues.add(redIntensity);
        _timestamps.add(DateTime.now().millisecondsSinceEpoch);

        // Keep only recent samples
        if (_redValues.length > _windowSize) {
          _redValues.removeAt(0);
          _timestamps.removeAt(0);
        }

        // Update signal quality
        _updateSignalQuality(redIntensity);

        // Calculate BPM if enough samples
        if (_redValues.length >= _minSamples) {
          _calculateBpm();
        }
      }
    } catch (e) {
      // Ignore processing errors
    } finally {
      _isProcessing = false;
    }
  }

  double _extractRedIntensity(CameraImage image) {
    try {
      // For YUV420 format, Y plane contains luminance
      final plane = image.planes[0];
      final bytes = plane.bytes;
      
      // Sample center region (where finger should be)
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final sampleSize = 50;
      
      double sum = 0;
      int count = 0;
      
      for (int y = centerY - sampleSize; y < centerY + sampleSize; y++) {
        for (int x = centerX - sampleSize; x < centerX + sampleSize; x++) {
          if (y >= 0 && y < image.height && x >= 0 && x < image.width) {
            final index = y * plane.bytesPerRow + x;
            if (index < bytes.length) {
              sum += bytes[index];
              count++;
            }
          }
        }
      }
      
      return count > 0 ? sum / count : 0;
    } catch (e) {
      return 0;
    }
  }

  void _updateSignalQuality(double intensity) {
    // Check if finger is properly placed based on intensity
    if (intensity < 100) {
      _signalQuality = 'Place finger';
    } else if (intensity > 200) {
      _signalQuality = 'Too bright';
    } else {
      // Check signal variance
      if (_redValues.length > 10) {
        final recent = _redValues.sublist(_redValues.length - 10);
        final variance = _calculateVariance(recent);
        
        if (variance < 5) {
          _signalQuality = 'Hold still';
        } else if (variance > 100) {
          _signalQuality = 'Too much movement';
        } else {
          _signalQuality = 'Good signal';
        }
      } else {
        _signalQuality = 'Detecting...';
      }
    }
  }

  void _calculateBpm() {
    if (_redValues.length < _minSamples) return;

    try {
      // Apply smoothing
      final smoothed = _movingAverage(_redValues, 3);
      
      // Detect peaks
      final peaks = _detectPeaks(smoothed);
      
      if (peaks.length >= 2) {
        // Calculate average time between peaks
        final intervals = <int>[];
        for (int i = 1; i < peaks.length; i++) {
          final interval = _timestamps[peaks[i]] - _timestamps[peaks[i - 1]];
          if (interval > 300 && interval < 2000) { // Valid heart rate range
            intervals.add(interval);
          }
        }
        
        if (intervals.isNotEmpty) {
          final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
          final bpm = (60000 / avgInterval).round();
          
          // Validate BPM range (40-200)
          if (bpm >= 40 && bpm <= 200) {
            // Smooth BPM updates
            _currentBpm = (_currentBpm * 0.7 + bpm * 0.3).round();
          }
        }
      }
    } catch (e) {
      // Ignore calculation errors
    }
  }

  List<double> _movingAverage(List<double> data, int windowSize) {
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - windowSize ~/ 2);
      final end = min(data.length, i + windowSize ~/ 2 + 1);
      final window = data.sublist(start, end);
      final avg = window.reduce((a, b) => a + b) / window.length;
      result.add(avg);
    }
    return result;
  }

  List<int> _detectPeaks(List<double> data) {
    final peaks = <int>[];
    final threshold = _calculateMean(data);
    
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > threshold &&
          data[i] > data[i - 1] &&
          data[i] > data[i + 1]) {
        // Ensure minimum distance between peaks
        if (peaks.isEmpty || i - peaks.last > 5) {
          peaks.add(i);
        }
      }
    }
    
    return peaks;
  }

  double _calculateMean(List<double> data) {
    if (data.isEmpty) return 0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _calculateVariance(List<double> data) {
    if (data.isEmpty) return 0;
    final mean = _calculateMean(data);
    final squaredDiffs = data.map((x) => pow(x - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / data.length;
  }

  void reset() {
    _redValues.clear();
    _timestamps.clear();
    _currentBpm = 0;
    _signalQuality = 'Place finger';
  }
}
