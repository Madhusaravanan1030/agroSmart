import 'package:flutter/foundation.dart';
import '../data/models/irrigation_log.dart';
import '../data/database/database_helper.dart';
import '../data/services/notification_service.dart';


// Controls the motor (auto/manual) and manages the irrigation log.

class IrrigationProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // ── Motor state ───────────────────────────────────────────────
  bool _isAutoMode = true;      // true = auto, false = manual
  bool _isMotorRunning = false;
  IrrigationLog? _activeSession; // the session currently in progress

  bool get isAutoMode => _isAutoMode;
  bool get isMotorRunning => _isMotorRunning;

  // ── Log state ─────────────────────────────────────────────────
  List<IrrigationLog> _logs = [];
  List<IrrigationLog> get logs => _logs;

  String _activeFilter = 'today'; // 'today' | 'week' | 'month'
  String get activeFilter => _activeFilter;

  // Summary stats shown at the top of the log screen
  int get totalSessions => _logs.where((l) => l.status == 'completed').length;

  String get totalDurationLabel {
    final minutes = _logs
        .where((l) => l.status == 'completed' && l.duration != null)
        .fold<int>(0, (sum, l) => sum + l.duration!.inMinutes);
    if (minutes >= 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '${minutes}m';
  }

  // ── Load logs from SQLite ─────────────────────────────────────

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
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        _logs = await _db.getLogsBetween(start, now);
        break;
      default: // 'today'
        _logs = await _db.getTodayLogs();
    }
    notifyListeners();
  }

  // ── Motor controls ────────────────────────────────────────────

  /// Toggle between auto and manual mode
  void toggleAutoMode(bool value) {
    _isAutoMode = value;
    notifyListeners();
  }

  /// Start the motor — creates a new log entry in SQLite
  Future<void> startMotor({String mode = 'manual'}) async {
    if (_isMotorRunning) return;

    _isMotorRunning = true;
    await NotificationService.instance.showMotorStarted(mode);

    final log = IrrigationLog(
      startTime: DateTime.now(),
      mode: mode,
      status: 'running',
    );

    final id = await _db.insertLog(log);
    _activeSession = log.copyWith(id: id);

    await loadLogs();
    notifyListeners();
  }

  /// Stop the motor — updates the log entry with end time
  Future<void> stopMotor() async {
    if (!_isMotorRunning || _activeSession == null) return;

    _isMotorRunning = false;

    final completed = _activeSession!.copyWith(
      endTime: DateTime.now(),
      status: 'completed',
    );

    await _db.updateLog(completed);

    await NotificationService.instance.showMotorStopped(completed.durationLabel);
    _activeSession = null;

    await loadLogs();
    notifyListeners();
  }

  /// Add a skipped session to the log (called by weather scheduler)
  Future<void> addSkippedLog(String reason) async {
    final log = IrrigationLog(
      startTime: DateTime.now(),
      mode: 'auto',
      status: 'skipped',
      skipReason: reason,
    );
    await _db.insertLog(log);
    await loadLogs();
  }

  /// Delete a log entry by id
  Future<void> deleteLog(int id) async {
    await _db.deleteLog(id);
    await loadLogs();
  }
}