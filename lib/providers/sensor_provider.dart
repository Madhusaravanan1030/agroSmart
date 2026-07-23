import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/sensor_data.dart';
import '../data/services/mock_sensor.dart';
import '../data/services/notification_service.dart';
// SensorProvider listens to the MockSensorService stream and
// notifies the UI whenever new readings arrive.

class SensorProvider extends ChangeNotifier {
  final _service = MockSensorService();

  SensorData _current = SensorData.initial();
  SensorData get current => _current;
  // Add this field to SensorProvider:
  double _lastSoilAlertMoisture = 100.0;

  // How long since the last irrigation (shown on dashboard)
  DateTime? _lastIrrigationTime;
  String get lastIrrigationLabel {
    if (_lastIrrigationTime == null) return 'Never';
    final diff = DateTime.now().difference(_lastIrrigationTime!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  StreamSubscription<SensorData>? _sub;

  /// Start listening to the mock sensor stream
  void startSimulation() {
    _service.start(intervalSeconds: 10);
    _sub = _service.stream.listen((data) async {
      
      _current = data;
      if (data.soilMoisture < 35 && _lastSoilAlertMoisture > 35) {
        await NotificationService.instance.showSoilAlert(data.soilMoisture);
      }
      _lastSoilAlertMoisture = data.soilMoisture;
      notifyListeners();
    });

  }

  /// Called when the motor turns on — soil moisture goes up
  void onMotorStarted() {
    _service.refillSoil();
    _lastIrrigationTime = DateTime.now();
  }

  void onMotorStopped() {
    // Nothing extra needed — soil will naturally drift down again
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}