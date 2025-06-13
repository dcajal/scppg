import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';

/// Widget showing play/pause control button
class PlayPauseControlWidget extends StatelessWidget {
  /// SCPPG controller instance
  final ScppgController scppgController;

  /// Callback when start sensing is requested
  final VoidCallback onStartSensing;

  /// Callback when stop sensing is requested
  final VoidCallback onStopSensing;

  /// Creates a play/pause control widget
  const PlayPauseControlWidget({
    super.key,
    required this.scppgController,
    required this.onStartSensing,
    required this.onStopSensing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Ink(
            decoration: const ShapeDecoration(
              color: Color.fromARGB(
                255,
                185,
                185,
                185,
              ), // Background color for the button
              shape: CircleBorder(),
            ),
            child: IconButton(
              alignment: Alignment.center,
              icon:
                  scppgController.isSensing
                      ? const Icon(
                        Icons.pause,
                        size: 30.0, // Play/pause icon size
                        color: Colors.black,
                      )
                      : const Icon(
                        Icons.play_arrow,
                        size: 30.0, // Play/pause icon size
                        color: Colors.black,
                      ),
              onPressed: () {
                scppgController.isSensing ? onStopSensing() : onStartSensing();
              },
            ),
          ),
        ],
      ),
    );
  }
}
