import 'dart:async';
import 'dart:math';
import '../models/sensor_data.dart';

// Simulates an Arduino/ESP sensor that sends readings every 10 seconds.
// Values drift slightly each tick to look realistic — not random jumps.

class MockSensorService {
  final _random = Random();
  Timer? _timer;

  // Current "real" values that drift over time
  double _temp = 30.0;
  double _humidity = 65.0;
  double _soilMoisture = 55.0;

  // StreamController broadcasts new readings to whoever is listening.
  // The SensorProvider will listen to this stream.
  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  /// Start emitting sensor data every [intervalSeconds] seconds
  void start({int intervalSeconds = 10}) {
    // Emit one reading immediately so the UI isn't blank on launch
    _emit();

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _drift();
      _emit();
    });
  }

  /// Stop the simulation (call this in provider dispose)
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Slightly move each value up or down — simulates natural sensor drift
  void _drift() {
    _temp = (_temp + _randomDelta(0.5)).clamp(25.0, 42.0);
    _humidity = (_humidity + _randomDelta(1.0)).clamp(30.0, 95.0);

    // Soil moisture slowly drops (evaporation) unless motor is running
    // When motor runs, IrrigationProvider will call refillSoil()
    _soilMoisture = (_soilMoisture - _randomDelta(0.3).abs()).clamp(10.0, 95.0);
  }

  /// Returns a small random positive or negative delta
  double _randomDelta(double maxChange) {
    return (_random.nextDouble() * maxChange * 2) - maxChange;
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(SensorData(
      temperature: double.parse(_temp.toStringAsFixed(1)),
      humidity: double.parse(_humidity.toStringAsFixed(1)),
      soilMoisture: double.parse(_soilMoisture.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    ));
  }

  /// Called by IrrigationProvider when motor turns ON — soil fills up
  void refillSoil() {
    _soilMoisture = (_soilMoisture + 20).clamp(0, 95);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}   