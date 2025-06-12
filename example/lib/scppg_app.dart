import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';
import 'package:get_it/get_it.dart';

import 'models/sensor_value.dart';
import 'services/ppg_data_service.dart';
import 'widgets/camera_preview_widget.dart';
import 'widgets/play_pause_control_widget.dart';
import 'widgets/toggle_controls_widget.dart';
import 'widgets/ppg_chart_widget.dart';

/// Main application widget for the SCPPG demo
class ScppgApp extends StatefulWidget {
  /// Creates the main SCPPG application widget
  const ScppgApp({super.key});

  @override
  ScppgAppState createState() => ScppgAppState();
}

/// State class for the SCPPG application
class ScppgAppState extends State<ScppgApp> {
  /// SCPPG controller instance from dependency injection
  final ScppgController _scppgController = GetIt.I<ScppgController>();

  // Buffer size for PPG data processing
  final int _bufferSize = 10;

  /// Listener callback for PPG data updates
  late final VoidCallback _ppgListener;

  /// Number of data points to display in the chart
  late final int _displayLength;

  /// List of plot values for the chart
  late List<SensorValue> _plotValues;

  /// Buffer for data processing
  late List<double> _buffer;

  /// Whether to render the chart
  bool _renderChart = false;

  @override
  void dispose() {
    _scppgController.removeListener(_ppgListener);
    _scppgController.stopSensing();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeDataStructures();
    _setupPPGListener();
  }

  /// Initialize data structures for PPG processing
  void _initializeDataStructures() {
    _displayLength = _scppgController.fps * 3; // 3 seconds display
    _plotValues = PPGDataService.initializePlotValues(_displayLength);
    _buffer = PPGDataService.initializeBuffer(_bufferSize);
  }

  /// Setup listener for PPG data updates
  void _setupPPGListener() {
    _ppgListener = () {
      if (mounted) {
        final ppgData = _scppgController.ppgData;
        if (ppgData != null) {
          PPGDataService.updatePlotWithPPGData(
            ppgData,
            _buffer,
            _plotValues,
            (renderChart) => _renderChart = renderChart,
          );
        }
        setState(() {});
      }
    };
    _scppgController.addListener(_ppgListener);
  }

  /// Start sensing and prepare data structures
  Future<void> _startSensing() async {
    _plotValues = PPGDataService.generateInitialTimeAxis(
      _displayLength,
      _scppgController.fps,
    );
    _buffer = PPGDataService.initializeBuffer(_bufferSize);
    await _scppgController.startSensing();
  }

  /// Stop sensing and clear data
  void _stopSensing() {
    _scppgController.stopSensing();
    _renderChart = false;
    _buffer = PPGDataService.initializeBuffer(_bufferSize);
  }

  /// Handle toggle button presses
  Future<void> _onTogglePressed(int index) async {
    switch (index) {
      case 0:
        _scppgController.isFlashOn = !_scppgController.isFlashOn;
        setState(() {});
        break;
      case 1:
        _scppgController.isFocusAndExposureLocked =
            !_scppgController.isFocusAndExposureLocked;
        setState(() {});
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayWidth = MediaQuery.of(context).size.width;
    final displayHeight = MediaQuery.of(context).size.height;
    final cardSeparation = 0.045 * displayWidth; // Card separation factor

    return MaterialApp(
      title: 'SCPPG Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(height: cardSeparation),

            // Camera and control row
            _buildCameraControlRow(displayWidth),

            const SizedBox(height: 10),

            // Toggle controls
            ToggleControlsWidget(
              scppgController: _scppgController,
              onPressed: _onTogglePressed,
            ),

            const SizedBox(height: 10),

            // PPG Chart
            _buildChartSection(displayHeight),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build camera and control row
  Widget _buildCameraControlRow(double displayWidth) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 0.04 * displayWidth, // Default horizontal padding
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CameraPreviewWidget(scppgController: _scppgController),
            PlayPauseControlWidget(
              scppgController: _scppgController,
              onStartSensing: _startSensing,
              onStopSensing: _stopSensing,
            ),
          ],
        ),
      ),
    );
  }

  /// Build chart section
  Widget _buildChartSection(double displayHeight) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 0.02 * displayHeight, // Default vertical padding
        ),
        child:
            _renderChart
                ? PPGChartWidget(_plotValues)
                : const SizedBox.shrink(),
      ),
    );
  }
}
