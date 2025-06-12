import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';

/// Widget displaying the camera preview or placeholder when not sensing
class CameraPreviewWidget extends StatelessWidget {
  /// SCPPG controller instance
  final ScppgController scppgController;

  /// Creates a camera preview widget
  const CameraPreviewWidget({super.key, required this.scppgController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0, // Camera preview horizontal padding
          vertical: 60.0, // Camera preview vertical padding
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Show camera preview when sensing, grey container otherwise
            scppgController.isSensing
                ? AspectRatio(
                  aspectRatio:
                      scppgController.cameraController.value.aspectRatio,
                  child: scppgController.cameraPreview,
                )
                : Container(color: Colors.grey),
            // Show camera icon when not sensing
            if (!scppgController.isSensing)
              const Icon(
                Icons.camera,
                size: 70.0, // Camera placeholder icon size
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }
}
