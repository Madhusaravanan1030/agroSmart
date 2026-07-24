import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/irrigation_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // ✅ Web guard — sqflite file paths don't exist on web
    // Use in-memory database so the app still runs without crashing
    if (kIsWeb) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createTables,
      );
    }

    // Mobile — use a real persistent file on device storage
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agrosmart.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

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

  Future<int> insertLog(IrrigationLog log) async {
    final db = await database;
    return await db.insert(
      'irrigation_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLog(IrrigationLog log) async {
    final db = await database;
    await db.update(
      'irrigation_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete('irrigation_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<IrrigationLog>> getAllLogs() async {
    final db = await database;
    final rows = await db.query('irrigation_logs', orderBy: 'startTime DESC');
    return rows.map(IrrigationLog.fromMap).toList();
  }

  Future<List<IrrigationLog>> getLogsBetween(DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.query(
      'irrigation_logs',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'startTime DESC',
    );
    return rows.map(IrrigationLog.fromMap).toList();
  }

  Future<List<IrrigationLog>> getTodayLogs() async {
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end   = start.add(const Duration(days: 1));
    return getLogsBetween(start, end);
  }

  Future<List<IrrigationLog>> getWeekLogs() async {
    final now   = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return getLogsBetween(start, now);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}