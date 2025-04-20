import 'dart:typed_data';
import 'package:flutter/services.dart';

class DetectorMethodChannel {
  final MethodChannel _channel = const MethodChannel(
    'com.example.flutter_object_detection/detector',
  );

  Future<List<dynamic>> detectObjects(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    try {
      final result = await _channel.invokeMethod('detectObjects', {
        'imageBytes': imageBytes,
        'width': width,
        'height': height,
      });

      if (result == null) {
        return [];
      }

      return result as List<dynamic>;
    } on PlatformException catch (e) {
      print('Platform exception in detectObjects: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error in detectObjects method channel: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      print('Error disposing detector: $e');
    }
  }
}
