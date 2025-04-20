import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomCameraController {
  final ResolutionPreset resolutionPreset;
  final bool enableAudio;
  final ImageFormatGroup imageFormatGroup;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  Timer? _captureTimer;

  // Stream controllers for state management
  final _isInitializedStreamController = StreamController<bool>.broadcast();
  Stream<bool> get isInitializedStream => _isInitializedStreamController.stream;

  // Stream for errors
  final _errorStreamController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorStreamController.stream;

  CustomCameraController({
    this.resolutionPreset = ResolutionPreset.medium,
    this.enableAudio = false,
    this.imageFormatGroup = ImageFormatGroup.yuv420,
  });

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _cameraController;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _errorStreamController.add('No cameras available');
        return;
      }

      await _initializeCamera(_cameras.first);
    } catch (e) {
      _errorStreamController.add('Error initializing camera: $e');
    }
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    try {
      _cameraController = CameraController(
        cameraDescription,
        resolutionPreset,
        enableAudio: enableAudio,
        imageFormatGroup: imageFormatGroup,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      _isInitialized = true;
      _isInitializedStreamController.add(true);
    } catch (e) {
      _errorStreamController.add('Error initializing camera controller: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length <= 1) {
      _errorStreamController.add('No alternative camera available');
      return;
    }

    final int currentCameraIndex = _cameras.indexOf(
      _cameraController!.description,
    );

    final int newCameraIndex = (currentCameraIndex + 1) % _cameras.length;

    await dispose();
    await _initializeCamera(_cameras[newCameraIndex]);
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (!_isInitialized) return;

    try {
      await _cameraController!.setFlashMode(mode);
    } catch (e) {
      _errorStreamController.add('Error setting flash mode: $e');
    }
  }

  void startCaptureLoop(
    Function(Uint8List, int, int) onImageCaptured, {
    Duration interval = const Duration(milliseconds: 300),
  }) {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(interval, (_) {
      captureImage().then((imageData) {
        if (imageData != null) {
          onImageCaptured(imageData.bytes, imageData.width, imageData.height);
        }
      });
    });
  }

  void stopCaptureLoop() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  Future<CapturedImageData?> captureImage() async {
    if (!_isInitialized || _cameraController == null) {
      return null;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      final Uint8List bytes = await image.readAsBytes();

      // Get image dimensions
      final Completer<Size> completer = Completer<Size>();
      final imageProvider = MemoryImage(bytes);
      imageProvider
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener((info, _) {
              completer.complete(
                Size(info.image.width.toDouble(), info.image.height.toDouble()),
              );
            }),
          );

      final Size imageSize = await completer.future;

      return CapturedImageData(
        bytes: bytes,
        width: imageSize.width.toInt(),
        height: imageSize.height.toInt(),
        path: image.path,
      );
    } catch (e) {
      _errorStreamController.add('Error capturing image: $e');
      return null;
    }
  }

  Future<void> pausePreview() async {
    if (!_isInitialized) return;
    try {
      await _cameraController!.pausePreview();
    } catch (e) {
      _errorStreamController.add('Error pausing preview: $e');
    }
  }

  Future<void> resumePreview() async {
    if (!_isInitialized) return;
    try {
      await _cameraController!.resumePreview();
    } catch (e) {
      _errorStreamController.add('Error resuming preview: $e');
    }
  }

  Future<void> dispose() async {
    stopCaptureLoop();
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
    _isInitializedStreamController.add(false);
  }

  void close() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _isInitializedStreamController.close();
    _errorStreamController.close();
  }
}

class CapturedImageData {
  final Uint8List bytes;
  final int width;
  final int height;
  final String path;

  CapturedImageData({
    required this.bytes,
    required this.width,
    required this.height,
    required this.path,
  });
}
