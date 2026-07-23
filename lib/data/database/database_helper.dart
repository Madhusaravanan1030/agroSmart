import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/irrigation_log.dart';

// Singleton — only one database instance exists for the whole app lifetime.
// Access it anywhere with: DatabaseHelper.instance

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Returns the open database, creating it on first call
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // getDatabasesPath() returns the correct folder on both Android and iOS
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agrosmart.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  // Called once when the database is first created on this device
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE irrigation_logs (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime   TEXT    NOT NULL,
        endTime     TEXT,
        mode        TEXT    NOT NULL,
        status      TEXT    NOT NULL,
        skipReason  TEXT
      )
    ''');
  }

  // ── CRUD operations ───────────────────────────────────────────

  /// Insert a new log entry. Returns the new row's id.
  Future<int> insertLog(IrrigationLog log) async {
    final db = await database;
    return await db.insert(
      'irrigation_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing log (e.g. when a session ends and we set endTime)
  Future<void> updateLog(IrrigationLog log) async {
    final db = await database;
    await db.update(
      'irrigation_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Delete a single log entry by id
  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete('irrigation_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// Fetch all logs, newest first
  Future<List<IrrigationLog>> getAllLogs() async {
    final db = await database;
    final rows = await db.query(
      'irrigation_logs',
      orderBy: 'startTime DESC',
    );
    return rows.map(IrrigationLog.fromMap).toList();
  }

  /// Fetch logs for a specific date range
  Future<List<IrrigationLog>> getLogsBetween(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.query(
      'irrigation_logs',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'startTime DESC',
    );
    return rows.map(IrrigationLog.fromMap).toList();
  }

  /// Fetch only today's logs
  Future<List<IrrigationLog>> getTodayLogs() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getLogsBetween(start, end);
  }

  /// Fetch this week's logs (last 7 days)
  Future<List<IrrigationLog>> getWeekLogs() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return getLogsBetween(start, now);
  }

  /// Close the database (rarely needed, but good practice)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}