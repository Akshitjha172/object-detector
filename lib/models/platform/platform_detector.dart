import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:object_detector/models/platform/detection_overlay_channel.dart';

class PlatformDetector {
  final DetectorMethodChannel _methodChannel = DetectorMethodChannel();

  Future<List<Map<String, dynamic>>> detectObjects(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    try {
      final result = await _methodChannel.detectObjects(
        imageBytes,
        width,
        height,
      );

      final List<Map<String, dynamic>> objects = [];

      for (final item in result) {
        // Convert to normalized rect (0.0-1.0)
        final normalizedLeft = item['left'] / width;
        final normalizedTop = item['top'] / height;
        final normalizedRight = item['right'] / width;
        final normalizedBottom = item['bottom'] / height;

        objects.add({
          'rect': Rect.fromLTRB(
            normalizedLeft,
            normalizedTop,
            normalizedRight,
            normalizedBottom,
          ),
          'label': item['label'],
          'confidence': item['confidence'],
        });
      }

      return objects;
    } catch (e) {
      print('Error in PlatformDetector: $e');
      return [];
    }
  }

  void dispose() {
    _methodChannel.dispose();
  }
}
