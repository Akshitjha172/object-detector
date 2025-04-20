import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart' as camera;
// Import the new camera controller
import 'camera_controller.dart'; // Make sure this points to the file you created

class CameraView extends StatefulWidget {
  final Function(Uint8List, int, int) onImageCaptured;

  const CameraView({super.key, required this.onImageCaptured});

  @override
  State createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late CustomCameraController _cameraController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController.stopCaptureLoop();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    _cameraController = CustomCameraController(
      resolutionPreset: camera.ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: camera.ImageFormatGroup.yuv420,
    );

    _cameraController.isInitializedStream.listen((isInitialized) {
      if (mounted && isInitialized) {
        setState(() {
          _isInitialized = isInitialized;
        });

        // Start capture loop once camera is initialized
        if (_isInitialized) {
          _cameraController.startCaptureLoop(widget.onImageCaptured);
        }
      }
    });

    _cameraController.errorStream.listen((errorMsg) {
      debugPrint(errorMsg);
      // You might want to display an error message to the user
    });

    await _cameraController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController.controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: camera.CameraPreview(_cameraController.controller!),
    );
  }
}
