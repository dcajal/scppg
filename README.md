<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# SCPPG - Smartphone Camera Photoplethysmography

[![pub package](https://img.shields.io/pub/v/scppg.svg)](https://pub.dev/packages/scppg)
[![pub points](https://img.shields.io/pub/points/scppg)](https://pub.dev/packages/scppg/score)
[![likes](https://img.shields.io/pub/likes/scppg)](https://pub.dev/packages/scppg/score)

A Flutter package for smartphone camera photoplethysmography (SCPPG) that enables heart rate monitoring using smartphone cameras.

## Links

- **[Package on pub.dev](https://pub.dev/packages/scppg)** - Main package page
- **[Package Score](https://pub.dev/packages/scppg/score)** - Package quality score and metrics
- **[API Documentation](https://pub.dev/documentation/scppg/latest/)** - Detailed API reference

## Features

- **Simple Camera Integration**: Easy-to-use controller for camera initialization and management
- **Permission Handling**: Built-in camera permission request management
- **RGB Extraction**: Real-time RGB signal extraction from camera frames
- **Finger Detection**: Automatic detection of finger presence on the camera
- **Customizable Settings**: Adjustable parameters for flash control, frame rate and detection thresholds
- **Real-time Monitoring**: Stream of camera data with timestamps for real-time analysis

## Getting started

### Prerequisites

- Flutter SDK 3.7.2 or higher
- Camera access on target devices
- Add required permissions to your app:

**For Android:**

Add these lines to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

**For iOS:**

Add these keys to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to measure heart rate</string>
```

## Usage

Check out the examples in the `/example` folder.

## API Reference

### ScppgController

The main controller class for the SCPPG functionality.

```dart
// Create a controller
final controller = ScppgController(fps: 30);

// Initialize (requests permissions)
await controller.init();

// Start/stop sensing
await controller.startSensing();
controller.stopSensing();

// Control flash and exposure
controller.isFlashOn = true;
controller.isFocusAndExposureLocked = true;

// Adjust finger detection sensitivity
controller.redRatioThreshold = 30; // 0-100
```

### SCPPGData

A data class representing the RGB values extracted from a camera frame.

```dart
// Access data
SCPPGData data = controller.ppgData;
double? redValue = data?.r;
double? greenValue = data?.g;
double? blueValue = data?.b;
DateTime? timestamp = data?.timestamp;
```

## Photoplethysmography Theory

Photoplethysmography (PPG) is an optical technique for detecting blood volume changes in microvascular tissue. When light from the phone's flash passes through the fingertip, the amount of light absorbed varies with each heartbeat. This package extracts the changes in red, green, and blue color channels, with the green channel typically providing the clearest signal for heart rate monitoring.

## Additional information

For more information on using SCPPG for heart rate monitoring, see:

- [Photoplethysmography Principles](https://en.wikipedia.org/wiki/Photoplethysmogram)

### Issues and Feedback

Please file issues, bugs, or feature requests in our [issue tracker](https://github.com/dcajal/scppg/issues).

### License

This project is licensed under the [MIT](LICENSE) License - see the LICENSE file for details.
