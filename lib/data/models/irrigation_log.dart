// One row in the irrigation log table.
// Every time the motor runs (auto or manual), one of these is created.

class IrrigationLog {
  final int? id;              // null until saved to SQLite
  final DateTime startTime;
  final DateTime? endTime;    // null if session is still running
  final String mode;          // 'auto' or 'manual'
  final String status;        // 'completed', 'skipped', 'upcoming', 'running'
  final String? skipReason;   // e.g. 'Rain forecast' — only set when skipped

  const IrrigationLog({
    this.id,
    required this.startTime,
    this.endTime,
    required this.mode,
    required this.status,
    this.skipReason,
  });

  // How long did this session last? Returns null if still running.
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  // Human-readable duration e.g. "35 min" or "1h 10min"
  String get durationLabel {
    final d = duration;
    if (d == null) return 'Running...';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes} min';
  }

  // ── SQLite helpers ────────────────────────────────────────────

  // Convert to a Map so sqflite can store it
  Map<String, dynamic> toMap() {
    return {
      'id':          id,
      'startTime':   startTime.toIso8601String(),
      'endTime':     endTime?.toIso8601String(),
      'mode':        mode,
      'status':      status,
      'skipReason':  skipReason,
    };
  }

  // Rebuild an IrrigationLog from a SQLite row
  factory IrrigationLog.fromMap(Map<String, dynamic> map) {
    return IrrigationLog(
      id:         map['id'] as int?,
      startTime:  DateTime.parse(map['startTime'] as String),
      endTime:    map['endTime'] != null
                    ? DateTime.parse(map['endTime'] as String)
                    : null,
      mode:       map['mode'] as String,
      status:     map['status'] as String,
      skipReason: map['skipReason'] as String?,
    );
  }

  // Create a copy with some fields updated (used when a session ends)
  IrrigationLog copyWith({
    int? id,
    DateTime? endTime,
    String? status,
    String? skipReason,
  }) {
    return IrrigationLog(
      id:         id ?? this.id,
      startTime:  startTime,
      endTime:    endTime ?? this.endTime,
      mode:       mode,
      status:     status ?? this.status,
      skipReason: skipReason ?? this.skipReason,
    );
  }
}