import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/sensor_value.dart';

/// Widget displaying the PPG data chart
class PPGChartWidget extends StatelessWidget {
  /// List of sensor values to display
  final List<SensorValue> data;

  /// Whether to show markers on the chart
  final bool markersVisible;

  /// Creates a PPG chart widget
  const PPGChartWidget(this.data, {super.key, this.markersVisible = false});

  @override
  Widget build(BuildContext context) {
    // Filter out null values for better chart rendering
    final validData =
        data
            .where((value) => value.time != null && value.value != null)
            .toList();

    return SfCartesianChart(
      primaryXAxis: const DateTimeAxis(
        intervalType: DateTimeIntervalType.seconds,
      ),
      series: <CartesianSeries<SensorValue, DateTime>>[
        LineSeries<SensorValue, DateTime>(
          dataSource: validData,
          xValueMapper: (SensorValue values, _) => values.time!,
          yValueMapper: (SensorValue values, _) => values.value!,
          width: 3.0, // Chart line width
          animationDuration: 0.0, // Chart animation duration
          markerSettings: MarkerSettings(isVisible: markersVisible),
          color: Colors.black, // Explicitly set line color
        ),
      ],
    );
  }
}
