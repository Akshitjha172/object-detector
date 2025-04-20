import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_detector/models/camera/camera_view.dart';
import 'package:object_detector/models/camera/permission_handler.dart';
import 'package:object_detector/models/detection/detection_overlay.dart';
import 'package:object_detector/models/platform/platform_detector.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({Key? key}) : super(key: key);

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final PlatformDetector _detector = PlatformDetector();
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isProcessing = false;
  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCameraPermission();
    });
  }

  Future<void> _requestCameraPermission() async {
    final hasPermission = await PermissionHandler.requestCameraPermission(
      context,
    );
    if (mounted) {
      setState(() {
        _hasCameraPermission = hasPermission;
      });
    }
  }

  void _onImageCaptured(Uint8List imageBytes, int width, int height) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final objects = await _detector.detectObjects(imageBytes, width, height);

      if (mounted) {
        setState(() {
          _detectedObjects = objects;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      debugPrint('Error detecting objects: $e');
    }
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Detection'), centerTitle: true),
      body: _hasCameraPermission
          ? _buildDetectionView()
          : _buildPermissionRequest(),
    );
  }

  Widget _buildDetectionView() {
    return Stack(
      children: [
        CameraView(onImageCaptured: _onImageCaptured),
        DetectionOverlay(detectedObjects: _detectedObjects),
        if (_isProcessing)
          const Positioned(
            top: 20,
            right: 20,
            child: CircularProgressIndicator(),
          ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Objects detected: ${_detectedObjects.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                backgroundColor: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Camera permission is required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This app needs camera access to detect objects',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _requestCameraPermission,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}
