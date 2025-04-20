import 'package:flutter/material.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> detectedObjects;

  const DetectionOverlay({Key? key, required this.detectedObjects})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: ObjectDetectionPainter(detectedObjects),
    );
  }
}

class ObjectDetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> detectedObjects;

  ObjectDetectionPainter(this.detectedObjects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.red;

    final textPaint = Paint()..color = Colors.black54;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (final object in detectedObjects) {
      final rect = object['rect'] as Rect;
      final label = object['label'] as String;
      final confidence = object['confidence'] as double;

      // Scale the rect to the current screen size
      final scaledRect = Rect.fromLTRB(
        rect.left * size.width,
        rect.top * size.height,
        rect.right * size.width,
        rect.bottom * size.height,
      );

      // Draw bounding box
      canvas.drawRect(scaledRect, paint);

      // Draw label background
      final textSpan = TextSpan(
        text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textBackgroundRect = Rect.fromLTWH(
        scaledRect.left,
        scaledRect.top - textPainter.height,
        textPainter.width + 8,
        textPainter.height,
      );
      canvas.drawRect(textBackgroundRect, textPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 4, scaledRect.top - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(ObjectDetectionPainter oldDelegate) {
    return oldDelegate.detectedObjects != detectedObjects;
  }
}
