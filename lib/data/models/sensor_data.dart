// This model holds one snapshot of sensor readings.
// Since we have no real hardware, all values are simulated.

class SensorData {
  final double temperature;   // °C
  final double humidity;      // %
  final double soilMoisture;  // %
  final DateTime timestamp;
  final bool isSimulated;     // always true in demo mode

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.timestamp,
    this.isSimulated = true,
  });

  // A safe "empty" state shown before the first reading arrives
  factory SensorData.initial() => SensorData(
        temperature: 0,
        humidity: 0,
        soilMoisture: 0,
        timestamp: DateTime.now(),
      );

  // Helper — is soil dry enough to trigger auto irrigation?
  bool get needsIrrigation => soilMoisture < 40.0;

  // Helper — is it too hot for afternoon watering?
  bool get heatStressRisk => temperature > 33.0;

  // Creates a copy with some fields changed (useful in providers)
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? soilMoisture,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}