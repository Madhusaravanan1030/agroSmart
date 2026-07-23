// ✅ Fix: removed the custom Color class at the bottom — it conflicted with dart:ui
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _rainAlertId  = 1001;
  static const int _soilAlertId  = 1002;
  static const int _motorStartId = 1003;
  static const int _motorStopId  = 1004;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // ✅ Fix: use Flutter's Color from dart:ui via material.dart — no custom class
        color: const Color(0xFF1D9E75),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  Future<void> showRainAlert(String day, int probability) async {
    await _plugin.show(
      _rainAlertId,
      '🌧 Rain expected $day',
      'Rain probability $probability% — irrigation will be skipped automatically',
      _details(
        channelId: 'rain_alerts',
        channelName: 'Rain Alerts',
        channelDesc: 'Alerts when rain is forecast and irrigation is skipped',
      ),
    );
  }

  Future<void> showSoilAlert(double moisture) async {
    await _plugin.show(
      _soilAlertId,
      '🌱 Soil moisture low',
      'Soil moisture at ${moisture.toInt()}% — consider starting irrigation',
      _details(
        channelId: 'soil_alerts',
        channelName: 'Soil Alerts',
        channelDesc: 'Alerts when soil moisture drops below the threshold',
      ),
    );
  }

  Future<void> showMotorStarted(String mode) async {
    await _plugin.show(
      _motorStartId,
      '💧 Irrigation started',
      '${mode == 'auto' ? 'Auto' : 'Manual'} irrigation is now running',
      _details(
        channelId: 'motor_status',
        channelName: 'Motor Status',
        channelDesc: 'Motor start and stop notifications',
      ),
    );
  }

  Future<void> showMotorStopped(String duration) async {
    await _plugin.show(
      _motorStopId,
      '✅ Irrigation completed',
      'Session finished — duration: $duration',
      _details(
        channelId: 'motor_status',
        channelName: 'Motor Status',
        channelDesc: 'Motor start and stop notifications',
      ),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}