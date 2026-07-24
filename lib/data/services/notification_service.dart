import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init() async {
    if (kIsWeb) return; // ✅ web guard — notifications not supported on web

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

  // ── Request permission (Android 13+) ─────────────────────────
  Future<void> requestPermission() async {
    if (kIsWeb) return; // ✅ web guard

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  // ── Notification details helper ───────────────────────────────
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
        color: const Color(0xFF1D9E75), // ✅ uses Flutter's Color from material.dart
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  // ── Rain forecast alert ───────────────────────────────────────
  Future<void> showRainAlert(String day, int probability) async {
    if (kIsWeb) return; // ✅ web guard

    await _plugin.show(
      _rainAlertId,
      '🌧 Rain expected $day',
      'Rain probability $probability% — irrigation will be skipped automatically',
      _details(
        channelId:   'rain_alerts',
        channelName: 'Rain Alerts',
        channelDesc: 'Alerts when rain is forecast and irrigation is skipped',
      ),
    );
  }

  // ── Soil moisture low alert ───────────────────────────────────
  Future<void> showSoilAlert(double moisture) async {
    if (kIsWeb) return; // ✅ web guard

    await _plugin.show(
      _soilAlertId,
      '🌱 Soil moisture low',
      'Soil moisture at ${moisture.toInt()}% — consider starting irrigation',
      _details(
        channelId:   'soil_alerts',
        channelName: 'Soil Alerts',
        channelDesc: 'Alerts when soil moisture drops below the threshold',
      ),
    );
  }

  // ── Motor started alert ───────────────────────────────────────
  Future<void> showMotorStarted(String mode) async {
    if (kIsWeb) return; // ✅ web guard

    await _plugin.show(
      _motorStartId,
      '💧 Irrigation started',
      '${mode == 'auto' ? 'Auto' : 'Manual'} irrigation is now running',
      _details(
        channelId:   'motor_status',
        channelName: 'Motor Status',
        channelDesc: 'Motor start and stop notifications',
      ),
    );
  }

  // ── Motor stopped alert ───────────────────────────────────────
  Future<void> showMotorStopped(String duration) async {
    if (kIsWeb) return; // ✅ web guard

    await _plugin.show(
      _motorStopId,
      '✅ Irrigation completed',
      'Session finished — duration: $duration',
      _details(
        channelId:   'motor_status',
        channelName: 'Motor Status',
        channelDesc: 'Motor start and stop notifications',
      ),
    );
  }

  // ── Cancel all ────────────────────────────────────────────────
  Future<void> cancelAll() async {
    if (kIsWeb) return; // ✅ web guard
    await _plugin.cancelAll();
  }
}