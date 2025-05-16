import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';
import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Register core services and controllers in GetIt
void registerDependencies() {
  // SCPPG controller
  GetIt.instance.registerSingleton<ScppgController>(ScppgController(fps: 30));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Register controller in GetIt
  GetIt.instance.registerSingleton<ScppgController>(ScppgController(fps: 30));

  // Initialize SCPPG controller
  await GetIt.instance<ScppgController>().init();

  runApp(Scppg());
}

/// Main widget for the SCPPG app
class Scppg extends StatefulWidget {
  const Scppg({super.key});

  @override
  ScppgState createState() {
    return ScppgState();
  }
}

class ScppgState extends State<Scppg> {
  final ScppgController _scppgController = GetIt.I<ScppgController>();
  late final VoidCallback _ppgListener;
  late final int _displayLength;
  late List<SensorValue> _plotValues;
  late List<double> _buffer;
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

    // Initialize plot values and buffer
    _displayLength = _scppgController.fps * 3;
    _plotValues = List.filled(
      _displayLength,
      SensorValue(null, null),
      growable: false,
    );
    _buffer = List.filled(10, double.nan, growable: false);

    // Add listener to update plot with PPG data
    _ppgListener = () {
      if (mounted) {
        final ppgData = _scppgController.ppgData;
        if (ppgData != null) {
          _updatePlotWithPPGData(ppgData);
        }
        setState(() {});
      }
    };
    _scppgController.addListener(_ppgListener);
  }

  /// Updates plot and buffer with PPG data
  void _updatePlotWithPPGData(SCPPGData data) {
    double? g = data.g;

    // Update buffer
    _buffer = _buffer.sublist(1)..add(g ?? double.nan);

    // Update plot values
    if (_buffer.any((e) => e.isNaN)) {
      _renderChart = false;
      _plotValues = _plotValues.sublist(1)
        ..add(SensorValue(data.timestamp, null));
    } else {
      _renderChart = true;
      _plotValues = _plotValues.sublist(1)
        ..add(SensorValue(data.timestamp, -g!));
    }
  }

  /// Generate initial time axis for the plot
  List<SensorValue> generateInitialTimeAxis() {
    final current = DateTime.now();
    final period = Duration(
      milliseconds: (1000 / _scppgController.fps).round(),
    );
    return List.generate(
      _displayLength,
      (i) => SensorValue(current.subtract(period * (_displayLength - i)), null),
    );
  }

  /// Start sensing and prepare the buffer and chart
  Future<void> startSensing() async {
    _plotValues = generateInitialTimeAxis();
    _buffer = List.filled(10, double.nan, growable: false);
    await _scppgController.startSensing();
  }

  /// Stop sensing and clear the buffer
  void stopSensing() {
    _scppgController.stopSensing();
    _renderChart = false;
    _buffer = List.filled(10, double.nan, growable: false);
  }

  /// Build the main widget
  @override
  Widget build(BuildContext context) {
    double displayWidth = MediaQuery.of(context).size.width;
    double displayHeight = MediaQuery.of(context).size.height;
    double cardSeparation = 0.045 * displayWidth;

    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            SizedBox(height: cardSeparation),

            /// Camera row
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.04 * displayWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ScppgCameraPreview(scppgController: _scppgController),
                    ScppgStatus(
                      scppgController: _scppgController,
                      onStartSensing: startSensing,
                      onStopSensing: stopSensing,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            ScppgToggleButtons(
              scppgController: _scppgController,
              onPressed: onPressed,
            ),

            SizedBox(height: 10),

            /// Plot
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 0.02 * displayHeight),
                child: _renderChart ? Chart(_plotValues) : null,
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Handle button presses for flash and exposure lock
  Future<void> onPressed(int index) async {
    switch (index) {
      case 0:
        // Toggle flash
        setState(() {
          if (_scppgController.cameraController.value.isInitialized) {
            _scppgController.isFlashOn = !_scppgController.isFlashOn;
            _scppgController.cameraController.setFlashMode(
              _scppgController.isFlashOn ? FlashMode.torch : FlashMode.off,
            );
          } else {
            debugPrint('Camera not initialized');
          }
        });
        break;
      case 1:
        // Toggle exposure lock
        setState(() {
          if (_scppgController.cameraController.value.isInitialized) {
            _scppgController.isFocusAndExposureLocked =
                !_scppgController.isFocusAndExposureLocked;
            if (_scppgController.isFocusAndExposureLocked) {
              _scppgController.cameraController.setFocusMode(FocusMode.locked);
              _scppgController.cameraController.setExposureMode(
                ExposureMode.locked,
              );
              debugPrint('Focus and exposure locked');
            } else {
              _scppgController.cameraController.setFocusMode(FocusMode.auto);
              _scppgController.cameraController.setExposureMode(
                ExposureMode.auto,
              );
              debugPrint('Focus and exposure unlocked');
            }
          } else {
            debugPrint('Camera not initialized');
          }
        });
        break;
      default:
        break;
    }
  }
}

/// Widget showing play/pause button.
class ScppgStatus extends StatelessWidget {
  final ScppgController scppgController;
  final VoidCallback onStartSensing;
  final VoidCallback onStopSensing;

  const ScppgStatus({
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
              color: Colors.grey,
              shape: CircleBorder(),
            ),
            child: IconButton(
              alignment: Alignment.center,
              icon:
                  scppgController.isSensing
                      ? const Icon(Icons.pause, size: 30, color: Colors.black)
                      : const Icon(
                        Icons.play_arrow,
                        size: 30,
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

/// Toggle buttons: flash, lock exposure
class ScppgToggleButtons extends StatelessWidget {
  final ScppgController scppgController;
  final ValueChanged<int> onPressed;

  const ScppgToggleButtons({
    super.key,
    required this.scppgController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    double displayWidth = MediaQuery.of(context).size.width;
    double displayHeight = MediaQuery.of(context).size.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ToggleButtons(
          constraints: BoxConstraints(
            minWidth: 0.28 * displayWidth,
            minHeight: 0.11 * displayHeight,
          ),
          borderRadius: BorderRadius.circular(10),
          borderColor: Colors.grey,
          fillColor: Colors.white,
          disabledColor: Colors.white,
          selectedColor: Colors.black,
          selectedBorderColor: Colors.grey,
          disabledBorderColor: Colors.white,
          onPressed: scppgController.isSensing ? onPressed : null,
          isSelected: [
            scppgController.isFlashOn,
            scppgController.isFocusAndExposureLocked,
          ],
          children: <Widget>[
            // Flash
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 0.07 * displayHeight,
                  child: Icon(
                    Icons.flashlight_on_outlined,
                    color:
                        scppgController.isSensing ? Colors.black : Colors.white,
                    size: 0.1 * displayWidth,
                  ),
                ),
                Text('Flash'),
              ],
            ),
            // Lock exposure
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 0.07 * displayHeight,
                  child: Icon(
                    scppgController.isFocusAndExposureLocked
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline,
                    color:
                        scppgController.isSensing ? Colors.black : Colors.white,
                    size: 0.1 * displayWidth,
                  ),
                ),
                Text(
                  scppgController.isFocusAndExposureLocked
                      ? 'Unlock exposure'
                      : 'Lock exposure',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Widget showing the camera preview or placeholder when not sensing
class ScppgCameraPreview extends StatelessWidget {
  final ScppgController scppgController;

  const ScppgCameraPreview({super.key, required this.scppgController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 60),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            scppgController.isSensing
                ? AspectRatio(
                  aspectRatio:
                      scppgController.cameraController.value.aspectRatio,
                  child: CameraPreview(scppgController.cameraController),
                )
                : Container(color: Colors.grey),
            if (!scppgController.isSensing)
              const Icon(Icons.camera, size: 70, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

/// Widget showing the chart with PPG data
class Chart extends StatelessWidget {
  final List<SensorValue> _data;
  final bool markersVisible;

  const Chart(this._data, {super.key, this.markersVisible = false});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.seconds,
        isVisible: false,
      ),
      primaryYAxis: NumericAxis(isVisible: false),
      series: <CartesianSeries<SensorValue, DateTime>>[
        LineSeries<SensorValue, DateTime>(
          dataSource: _data,
          xValueMapper: (SensorValue values, _) => values.time,
          yValueMapper: (SensorValue values, _) => values.value,
          width: 3,
          animationDuration: 0,
          markerSettings: MarkerSettings(isVisible: markersVisible),
        ),
      ],
      backgroundColor: const Color.fromARGB(0, 255, 255, 255),
      palette: [Colors.black],
      borderWidth: 0,
      plotAreaBorderWidth: 0,
    );
  }
}

/// Class representing a sensor value with time and value
class SensorValue {
  SensorValue(this.time, this.value);
  final DateTime? time;
  final double? value;
}
