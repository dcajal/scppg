import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';

/// Toggle buttons widget for flash and exposure lock controls
class ToggleControlsWidget extends StatelessWidget {
  /// SCPPG controller instance
  final ScppgController scppgController;

  /// Callback when a toggle button is pressed
  final ValueChanged<int> onPressed;

  /// Creates a toggle controls widget
  const ToggleControlsWidget({
    super.key,
    required this.scppgController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final displayWidth = MediaQuery.of(context).size.width;
    final displayHeight = MediaQuery.of(context).size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ToggleButtons(
          constraints: BoxConstraints(
            minWidth: 0.28 * displayWidth, // Toggle button width factor
            minHeight: 0.11 * displayHeight, // Toggle button height factor
          ),
          borderRadius: BorderRadius.circular(10),
          borderColor: Colors.grey[400],
          fillColor: Colors.white,
          disabledColor: Colors.white,
          selectedColor: Colors.black,
          selectedBorderColor: Colors.grey[400],
          disabledBorderColor: Colors.white,
          onPressed: scppgController.isSensing ? onPressed : null,
          isSelected: [
            scppgController.isFlashOn,
            scppgController.isFocusAndExposureLocked,
          ],
          children: [
            _buildFlashToggle(displayWidth, displayHeight),
            _buildExposureLockToggle(displayWidth, displayHeight),
          ],
        );
      },
    );
  }

  /// Build flash toggle button
  Widget _buildFlashToggle(double displayWidth, double displayHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 0.07 * displayHeight, // Icon height factor
          child: Icon(
            Icons.flashlight_on_outlined,
            color: scppgController.isSensing ? Colors.black : Colors.white,
            size: 0.1 * displayWidth, // Icon size factor
          ),
        ),
        const Text('Flash'),
      ],
    );
  }

  /// Build exposure lock toggle button
  Widget _buildExposureLockToggle(double displayWidth, double displayHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 0.07 * displayHeight, // Icon height factor
          child: Icon(
            scppgController.isFocusAndExposureLocked
                ? Icons.lock_open_outlined
                : Icons.lock_outline,
            color: scppgController.isSensing ? Colors.black : Colors.white,
            size: 0.1 * displayWidth, // Icon size factor
          ),
        ),
        Text(
          scppgController.isFocusAndExposureLocked
              ? 'Unlock exposure'
              : 'Lock exposure',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
