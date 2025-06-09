import 'dart:async';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Data class for SCPPG sensor readings
class SCPPGData {
  final double? r;
  final double? g;
  final double? b;
  final DateTime? timestamp;

  SCPPGData({this.r, this.g, this.b, this.timestamp});
}

/// Controller managing SCPPG sensing and recording logic.
class ScppgController extends ChangeNotifier {
  /// Camera frames per second
  final int fps;

  /// Constructor
  ScppgController({this.fps = 30});

  // Threshold for red ratio (finger detection)
  int _redRatioThreshold = 30;
  int get redRatioThreshold => _redRatioThreshold;
  set redRatioThreshold(int value) {
    _redRatioThreshold = value;
    notifyListeners();
  }

  bool _isSensing = false;
  bool get isSensing => _isSensing;

  bool _isFocusAndExposureLocked = false;
  bool get isFocusAndExposureLocked => _isFocusAndExposureLocked;

  /// Allow external toggle of exposure lock state
  set isFocusAndExposureLocked(bool value) {
    _isFocusAndExposureLocked = value;
    if (_cameraController != null) {
      _cameraController!.setFocusMode(
        value ? FocusMode.locked : FocusMode.auto,
      );
      _cameraController!.setExposureMode(
        value ? ExposureMode.locked : ExposureMode.auto,
      );
    }
    notifyListeners();
  }

  bool _isFlashOn = false;
  bool get isFlashOn => _isFlashOn;

  /// Allow external toggle of flash state
  set isFlashOn(bool value) {
    _isFlashOn = value;
    if (_cameraController != null) {
      _cameraController!.setFlashMode(value ? FlashMode.torch : FlashMode.off);
    }
    notifyListeners();
  }

  /// Camera controller instance
  CameraController? _cameraController;
  CameraController get cameraController => _cameraController!;

  /// Allow external access to the camera controller
  set cameraController(CameraController? controller) {
    _cameraController = controller;
    notifyListeners();
  }

  /// Timestamp of the last frame
  DateTime? _now;
  DateTime? get now => _now;

  /// SCPPG data object
  SCPPGData? _scppgData;
  SCPPGData? get ppgData => _scppgData;

  /// Initialize permissions or other startup tasks
  Future<void> init() async {
    await _requestPermissions();
  }

  /// Dispose resources when no longer needed
  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  /// Start camera stream
  Future<void> startSensing() async {
    await _initController();
    _isSensing = true;
    notifyListeners();
  }

  /// Stop sensing: disable stream, reset state
  void stopSensing() {
    _disposeController();
    _isFlashOn = false;
    _isFocusAndExposureLocked = false;
    _isSensing = false;
    notifyListeners();
  }

  /// Initialize the camera controller
  Future<void> _initController() async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
      ResolutionPreset.low,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
      fps: fps,
    );
    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off);
    await _cameraController!.setFocusMode(FocusMode.auto);
    await _cameraController!.setExposureMode(ExposureMode.auto);
    _cameraController!.startImageStream(_scanImage);
  }

  /// Dispose of the camera controller
  void _disposeController() {
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _cameraController?.dispose();
    _cameraController = null;
  }

  /// Process camera image frames
  void _scanImage(CameraImage image) {
    _now = DateTime.now();

    // Compute YUV averages
    double y =
        image.planes[0].bytes.reduce((a, b) => a + b) /
        image.planes[0].bytes.length;
    double u, v;
    if (image.planes.length == 3) {
      u =
          image.planes[1].bytes.reduce((a, b) => a + b) /
          image.planes[1].bytes.length;
      v =
          image.planes[2].bytes.reduce((a, b) => a + b) /
          image.planes[2].bytes.length;
    } else {
      var bytes = image.planes[1].bytes;
      double sumU = 0, sumV = 0;
      for (int i = 0; i < bytes.length; i += 2) {
        sumU += bytes[i];
        sumV += bytes[i + 1];
      }
      u = sumU / (bytes.length / 2);
      v = sumV / (bytes.length / 2);
    }

    // Convert to RGB
    double r = (y + 1.402 * (v - 128)).clamp(0.0, 255.0);
    double g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).clamp(
      0.0,
      255.0,
    );
    double b = (y + 1.772 * (u - 128)).clamp(0.0, 255.0);

    double framePower = r + g + b;
    if ((r / framePower) < (redRatioThreshold / 100.0)) {
      r = double.nan;
      g = double.nan;
      b = double.nan;
    }

    // Update the SCPPG data object and notify listeners
    _scppgData = SCPPGData(r: r, g: g, b: b, timestamp: _now);

    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    /// Request Camera permission if needed
    PermissionStatus cameraPermissionStatus = await Permission.camera.request();
    if (cameraPermissionStatus == PermissionStatus.granted) {
      debugPrint("Camera permission granted");
    } else {
      debugPrint("Camera permission not granted");
    }
  }
}
