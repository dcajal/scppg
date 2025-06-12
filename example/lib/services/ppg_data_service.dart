import 'package:scppg/scppg.dart';
import '../models/sensor_value.dart';

/// Service class handling PPG data processing and chart updates
class PPGDataService {
  /// Updates plot and buffer with PPG data
  static void updatePlotWithPPGData(
    SCPPGData data,
    List<double> buffer,
    List<SensorValue> plotValues,
    Function(bool) setRenderChart,
  ) {
    double? g = data.g;

    // Update buffer - removes oldest value and adds new one
    buffer.removeAt(0);
    buffer.add(g ?? double.nan);

    // Update plot values based on buffer validity
    if (buffer.any((e) => e.isNaN)) {
      setRenderChart(false);
      plotValues.removeAt(0);
      plotValues.add(SensorValue(data.timestamp, null));
    } else {
      setRenderChart(true);
      plotValues.removeAt(0);
      plotValues.add(SensorValue(data.timestamp, -g!));
    }
  }

  /// Generate initial time axis for the plot
  static List<SensorValue> generateInitialTimeAxis(int displayLength, int fps) {
    final current = DateTime.now();
    final period = Duration(milliseconds: (1000 / fps).round());
    return List.generate(
      displayLength,
      (i) => SensorValue(current.subtract(period * (displayLength - i)), null),
    );
  }

  /// Initialize empty buffer with NaN values
  static List<double> initializeBuffer(int bufferSize) {
    return List.filled(bufferSize, double.nan, growable: false);
  }

  /// Initialize empty plot values list
  static List<SensorValue> initializePlotValues(int displayLength) {
    return List.filled(displayLength, SensorValue(null, null), growable: false);
  }
}
