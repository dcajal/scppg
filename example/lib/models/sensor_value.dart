/// Data model representing a sensor value with timestamp
class SensorValue {
  /// Creates a sensor value with time and value
  SensorValue(this.time, this.value);

  /// Timestamp when the sensor value was recorded
  final DateTime? time;

  /// The actual sensor value (PPG data)
  final double? value;
}
