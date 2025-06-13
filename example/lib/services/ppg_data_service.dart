import 'package:scppg/scppg.dart';
import '../models/sensor_value.dart';

/// Service class handling PPG data processing and chart updates
class PPGDataService {
  /// Shift elements in a fixed-length list to the left and update the last element
  static void shiftAndUpdate<T>(List<T> list, T newValue) {
    for (int i = 0; i < list.length - 1; i++) {
      list[i] = list[i + 1];
    }
    list[list.length - 1] = newValue;
  }

  /// Updates plot and buffer with PPG data
  static void updatePlotWithPPGData(
    SCPPGData data,
    List<double> buffer,
    List<SensorValue> plotValues,
    Function(bool) setRenderChart,
  ) {
    double? y = data.y;

    // Shift buffer values and update the last element
    shiftAndUpdate(buffer, y ?? double.nan);

    // Update plot values based on buffer validity
    if (buffer.any((e) => e.isNaN)) {
      setRenderChart(false);
      shiftAndUpdate(plotValues, SensorValue(data.timestamp, null));
    } else {
      setRenderChart(true);
      shiftAndUpdate(plotValues, SensorValue(data.timestamp, -y!));
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
