import 'package:flutter/foundation.dart';
import '../data/models/irrigation_log.dart';
import '../data/database/database_helper.dart';
import '../data/services/notification_service.dart';

class IrrigationProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // ── Motor state ───────────────────────────────────────────────
  bool _isAutoMode     = true;
  bool _isMotorRunning = false;
  IrrigationLog? _activeSession;

  bool get isAutoMode     => _isAutoMode;
  bool get isMotorRunning => _isMotorRunning;

  // ── Log state ─────────────────────────────────────────────────
  List<IrrigationLog> _logs = [];
  List<IrrigationLog> get logs => _logs;

  String _activeFilter = 'today';
  String get activeFilter => _activeFilter;

  int get totalSessions =>
      _logs.where((l) => l.status == 'completed').length;

  String get totalDurationLabel {
    final minutes = _logs
        .where((l) => l.status == 'completed' && l.duration != null)
        .fold<int>(0, (sum, l) => sum + l.duration!.inMinutes);
    if (minutes >= 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '${minutes}m';
  }

  // ── Load logs ─────────────────────────────────────────────────

  Future<void> loadLogs() async {
    await _applyFilter(_activeFilter);
  }

  Future<void> setFilter(String filter) async {
    _activeFilter = filter;
    await _applyFilter(filter);
  }

  Future<void> _applyFilter(String filter) async {
    switch (filter) {
      case 'week':
        _logs = await _db.getWeekLogs();
        break;
      case 'month':
        final now   = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        _logs = await _db.getLogsBetween(start, now);
        break;
      default:
        _logs = await _db.getTodayLogs();
    }
    notifyListeners();
  }

  // ── Motor controls ────────────────────────────────────────────

  void toggleAutoMode(bool value) {
    _isAutoMode = value;
    notifyListeners();
  }

  Future<void> startMotor({String mode = 'manual'}) async {
    if (_isMotorRunning) return;

    _isMotorRunning = true;
    notifyListeners(); // ✅ update UI immediately before async work

    try {
      // Save log to database
      final log = IrrigationLog(
        startTime: DateTime.now(),
        mode: mode,
        status: 'running',
      );
      final id = await _db.insertLog(log);
      _activeSession = log.copyWith(id: id);

      // ✅ Only show notification on mobile — web guard inside the service
      await NotificationService.instance.showMotorStarted(mode);

      await loadLogs();
    } catch (e) {
      // If DB fails on web (in-memory), still keep motor running in UI
      debugPrint('startMotor error: $e');
    }

    notifyListeners();
  }

  Future<void> stopMotor() async {
    if (!_isMotorRunning) return;

    _isMotorRunning = false;
    notifyListeners(); // ✅ update UI immediately

    try {
      if (_activeSession != null) {
        final completed = _activeSession!.copyWith(
          endTime: DateTime.now(),
          status: 'completed',
        );
        await _db.updateLog(completed);

        // ✅ Only show notification on mobile — web guard inside the service
        await NotificationService.instance
            .showMotorStopped(completed.durationLabel);

        _activeSession = null;
      }
      await loadLogs();
    } catch (e) {
      debugPrint('stopMotor error: $e');
    }

    notifyListeners();
  }

  Future<void> addSkippedLog(String reason) async {
    try {
      final log = IrrigationLog(
        startTime:  DateTime.now(),
        mode:       'auto',
        status:     'skipped',
        skipReason: reason,
      );
      await _db.insertLog(log);
      await loadLogs();
    } catch (e) {
      debugPrint('addSkippedLog error: $e');
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _db.deleteLog(id);
      await loadLogs();
    } catch (e) {
      debugPrint('deleteLog error: $e');
    }
  }
}