import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Data class representing a single SCPPG (Smartphone Camera-based Photoplethysmography) reading
///
/// Contains RGB color and Y (luminance) values extracted from camera frames and
/// the timestamp when the measurement was taken.
class SCPPGData {
  /// Red color component (0-255), null if finger not detected
  final double? r;

  /// Green color component (0-255), null if finger not detected
  final double? g;

  /// Blue color component (0-255), null if finger not detected
  final double? b;

  /// Luminance (brightness) value (0-255), null if finger not detected
  final double? y;

  /// Timestamp when this reading was captured
  final DateTime? timestamp;

  /// Creates a new SCPPG data instance
  SCPPGData({this.r, this.g, this.b, this.y, this.timestamp});
}

/// Controller for managing SCPPG (Smartphone Camera-based Photoplethysmography) sensing
///
/// This controller handles camera initialization, image processing for PPG signal extraction,
/// and provides a reactive interface for monitoring physiological signals through the smartphone camera.
/// It processes camera frames to extract RGB values that can be used for heart rate detection.
class ScppgController extends ChangeNotifier {
  // =============================================================================
  // CONSTRUCTOR & CONFIGURATION
  // =============================================================================

  /// Target camera frames per second for sensing
  final int fps;

  /// Creates a new SCPPG controller instance
  ///
  /// [fps] - Camera frames per second (default: 30)
  ScppgController({this.fps = 30});

  // =============================================================================
  // SENSING CONFIGURATION PROPERTIES
  // =============================================================================

  /// Threshold for red color ratio used in finger detection (0-100)
  ///
  /// Lower values are more sensitive to finger detection.
  /// If the red ratio in a frame is below this threshold, the frame is considered
  /// as not having a finger covering the camera.
  int _redRatioThreshold = 30;
  int get redRatioThreshold => _redRatioThreshold;
  set redRatioThreshold(int value) {
    _redRatioThreshold = value;
    notifyListeners();
  }

  // =============================================================================
  // SENSING STATE PROPERTIES
  // =============================================================================

  /// Whether the controller is currently sensing/processing camera frames
  bool _isSensing = false;
  bool get isSensing => _isSensing;

  /// Whether camera focus and exposure are locked for consistent readings
  ///
  /// Locking focus and exposure helps maintain consistent lighting conditions
  /// which is crucial for accurate PPG signal extraction.
  bool _isFocusAndExposureLocked = false;
  bool get isFocusAndExposureLocked => _isFocusAndExposureLocked;

  /// Controls camera focus and exposure lock state
  ///
  /// When true, locks both focus and exposure modes to maintain consistent
  /// camera settings during PPG sensing.
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

  /// Whether the camera flash/torch is currently on
  ///
  /// The flash is used as a light source to illuminate the finger
  /// for better PPG signal quality.
  bool _isFlashOn = false;
  bool get isFlashOn => _isFlashOn;

  /// Controls camera flash/torch state
  ///
  /// Toggles between torch mode (continuous light) and off.
  /// The torch provides consistent illumination for PPG sensing.
  set isFlashOn(bool value) {
    _isFlashOn = value;
    if (_cameraController != null) {
      _cameraController!.setFlashMode(value ? FlashMode.torch : FlashMode.off);
    }
    notifyListeners();
  }

  // =============================================================================
  // CAMERA CONTROLLER PROPERTIES
  // =============================================================================

  /// Internal camera controller instance
  CameraController? _cameraController;

  /// Provides access to the camera controller
  ///
  /// Throws an exception if the controller is not initialized.
  CameraController get cameraController => _cameraController!;

  /// Allows external setting of the camera controller
  ///
  /// This is primarily used for testing or advanced use cases.
  set cameraController(CameraController? controller) {
    _cameraController = controller;
    notifyListeners();
  }

  // =============================================================================
  // DATA PROPERTIES
  // =============================================================================

  /// Timestamp of the most recent frame processed
  DateTime? _now;
  DateTime? get now => _now;

  /// Most recent SCPPG data reading
  ///
  /// Contains RGB values and timestamp from the latest processed camera frame.
  /// Values will be null if no finger is detected.
  SCPPGData? _scppgData;
  SCPPGData? get ppgData => _scppgData;

  // =============================================================================
  // PUBLIC API METHODS
  // =============================================================================

  /// Initializes the SCPPG controller
  ///
  /// This method should be called before starting sensing operations.
  /// It requests necessary permissions and prepares the controller for use.
  Future<void> init() async {
    await _requestPermissions();
  }

  /// Starts SCPPG sensing
  ///
  /// Initializes the camera controller and begins processing camera frames
  /// for PPG signal extraction. The controller will start emitting data
  /// through the [ppgData] property and notify listeners of changes.
  Future<void> startSensing() async {
    await _initController();
    _isSensing = true;
    notifyListeners();
  }

  /// Stops SCPPG sensing and resets state
  ///
  /// Disposes of camera resources, stops image processing, and resets
  /// all sensing-related state to default values.
  void stopSensing() {
    _isFlashOn = false;
    _isFocusAndExposureLocked = false;
    _isSensing = false;
    _disposeController();
    notifyListeners();
    debugPrint('[ScppgController] Sensing stopped and controller disposed');
  }

  /// Provides a camera preview widget
  ///
  /// Returns a [CameraPreview] widget that can be used to display
  /// the camera feed in the UI.
  ///
  /// Throws an exception if the camera controller is not initialized.
  CameraPreview get cameraPreview {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception("Camera controller is not initialized");
    }
    return CameraPreview(_cameraController!);
  }

  /// Disposes of resources when the controller is no longer needed
  ///
  /// This method should be called when the controller is being destroyed
  /// to properly clean up camera resources and prevent memory leaks.
  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  // =============================================================================
  // PRIVATE CAMERA MANAGEMENT METHODS
  // =============================================================================

  /// Initializes the camera controller with optimal settings for PPG sensing
  ///
  /// This method:
  /// - Finds and selects the back camera (preferred for PPG)
  /// - Configures camera settings for optimal signal extraction
  /// - Sets up the image stream for real-time processing
  Future<void> _initController() async {
    // Get list of available cameras
    List<CameraDescription> cameras = await availableCameras();

    // Ensure at least one camera is available
    if (cameras.isEmpty) {
      throw Exception("No cameras available on this device");
    }

    // Prefer back camera for PPG sensing, fallback to first available
    CameraDescription selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // Initialize camera controller with PPG-optimized settings
    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.low, // Low resolution is sufficient for PPG
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false, // Audio not needed for PPG
      fps: fps,
    );

    // Initialize and configure camera
    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off);
    await _cameraController!.setFocusMode(FocusMode.auto);
    await _cameraController!.setExposureMode(ExposureMode.auto);

    // Start processing camera frames
    _cameraController!.startImageStream(_processImageFrame);
    debugPrint('[ScppgController] Camera stream started successfully');
  }

  /// Safely disposes of the camera controller and stops image processing
  ///
  /// This method handles cleanup gracefully, ensuring no exceptions
  /// are thrown even if the controller is already disposed.
  void _disposeController() {
    // Stop image stream safely
    if (_cameraController == null) {
      debugPrint('[ScppgController] Camera controller is already disposed');
      return;
    }

    try {
      _cameraController?.stopImageStream();
    } catch (error) {
      debugPrint('[ScppgController] Error stopping image stream: $error');
    }

    // Dispose controller and reset reference
    _cameraController?.dispose();
    _cameraController = null;

    debugPrint('[ScppgController] Camera controller disposed');
  }

  // =============================================================================
  // PRIVATE IMAGE PROCESSING METHODS
  // =============================================================================

  /// Processes each camera frame to extract RGB values for PPG analysis
  ///
  /// This method is called for every camera frame and performs:
  /// 1. Platform-specific image format conversion (iOS BGRA vs Android YUV)
  /// 2. RGB value extraction from image data
  /// 3. Finger detection based on red color ratio
  /// 4. Data packaging and notification of listeners
  void _processImageFrame(CameraImage image) {
    // Record timestamp for this frame
    _now = DateTime.now();

    // Extract RGB values based on platform and image format
    final rgbyValues = _extractRGBYFromImage(image);

    if (rgbyValues == null) {
      // Unsupported format or processing error
      return;
    }

    double r = rgbyValues['r']!;
    double g = rgbyValues['g']!;
    double b = rgbyValues['b']!;
    double y = rgbyValues['y']!;

    // Apply finger detection algorithm
    final processedValues = _applyFingerDetection(r, g, b, y);

    // Update SCPPG data and notify listeners
    _scppgData = SCPPGData(
      r: processedValues['r'],
      g: processedValues['g'],
      b: processedValues['b'],
      y: processedValues['y'],
      timestamp: _now,
    );

    notifyListeners();
  }

  /// Extracts RGB values from camera image based on platform-specific formats
  ///
  /// Returns a map with 'r', 'g', 'b', 'y' keys containing double values,
  /// or null if the image format is unsupported.
  Map<String, double>? _extractRGBYFromImage(CameraImage image) {
    // Calculate average Y (luminance) value
    double y =
        image.planes[0].bytes.reduce((a, b) => a + b) /
        image.planes[0].bytes.length;

    double u = 0.0, v = 0.0;
    double r = 0.0, g = 0.0, b = 0.0;

    // Extract U and V chrominance values
    if (image.planes.length == 3 &&
        image.planes[1].bytes[0] == image.planes[2].bytes[0]) {
      // Separate U and V planes, as in Android YUV_420_888
      u =
          image.planes[1].bytes.reduce((a, b) => a + b) /
          image.planes[1].bytes.length;
      v =
          image.planes[2].bytes.reduce((a, b) => a + b) /
          image.planes[2].bytes.length;
    } else {
      // Interleaved UV plane, as in iOS kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      var uvBytes = image.planes[1].bytes;
      double sumU = 0, sumV = 0;

      for (int i = 0; i < uvBytes.length; i += 2) {
        sumU += uvBytes[i]; // U values at even indices
        sumV += uvBytes[i + 1]; // V values at odd indices
      }

      u = sumU / (uvBytes.length / 2);
      v = sumV / (uvBytes.length / 2);
    }

    // Convert YUV to RGB with platform-specific range handling
    double yNorm, uNorm, vNorm;

    if (Platform.isIOS) {
      // iOS uses video range: Y [16,235], U/V [16,240]
      yNorm = (y - 16) / 219; // 235 - 16 = 219
      uNorm = (u - 16) / 224; // 240 - 16 = 224
      vNorm = (v - 16) / 224; // 240 - 16 = 224
    } else if (Platform.isAndroid) {
      // Android uses full range: Y, U, V [0,255]
      yNorm = y / 255;
      uNorm = u / 255;
      vNorm = v / 255;
    } else {
      debugPrint(
        "[ScppgController] Unsupported platform ${Platform.operatingSystem}",
      );
      return null;
    }

    // Center U and V. 0.5 represents neutral color (e.g. no blue-yellow or red-green bias)
    uNorm = uNorm - 0.5;
    vNorm = vNorm - 0.5;

    // YUV to RGB conversion using ITU-R BT.601 standard
    r = yNorm + 1.402 * vNorm;
    g = yNorm - 0.344136 * uNorm - 0.714136 * vNorm;
    b = yNorm + 1.772 * uNorm;

    // Clamp to [0,1] range and scale to [0,255]
    r = (r.clamp(0.0, 1.0) * 255).round().toDouble();
    g = (g.clamp(0.0, 1.0) * 255).round().toDouble();
    b = (b.clamp(0.0, 1.0) * 255).round().toDouble();

    debugPrint(
      "[ScppgController] Extracted RGBY values: r=$r, g=$g, b=$b, y=$y",
    );

    return {'r': r, 'g': g, 'b': b, 'y': y};
  }

  /// Applies finger detection algorithm based on red color ratio
  ///
  /// If the red component ratio is below the threshold, it indicates
  /// that no finger is covering the camera, so all values are set to NaN.
  /// This helps filter out noise when the user isn't properly covering the camera.
  Map<String, double?> _applyFingerDetection(
    double r,
    double g,
    double b,
    double y,
  ) {
    double totalPower = r + g + b;

    // Check if finger is detected based on red ratio threshold
    if (totalPower > 0 && (r / totalPower) >= (redRatioThreshold / 100.0)) {
      // Finger detected - return actual RGB values
      return {'r': r, 'g': g, 'b': b, 'y': y};
    } else {
      // No finger detected - return NaN values to indicate invalid reading
      return {
        'r': double.nan,
        'g': double.nan,
        'b': double.nan,
        'y': double.nan,
      };
    }
  }

  // =============================================================================
  // PRIVATE PERMISSION MANAGEMENT
  // =============================================================================

  /// Requests camera permission from the user
  ///
  /// This method handles the permission request process and logs the result.
  /// Camera permission is required for PPG sensing functionality.
  Future<void> _requestPermissions() async {
    try {
      PermissionStatus cameraPermissionStatus =
          await Permission.camera.request();

      if (cameraPermissionStatus == PermissionStatus.granted) {
        debugPrint("[ScppgController] Camera permission granted successfully");
      } else {
        debugPrint("[ScppgController] Camera permission denied by user");
      }
    } catch (error) {
      debugPrint(
        "[ScppgController] Error requesting camera permission: $error",
      );
    }
  }
}
