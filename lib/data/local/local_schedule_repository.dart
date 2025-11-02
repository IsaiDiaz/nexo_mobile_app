import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:nexo/model/available_schedule.dart';

class LocalScheduleRepository {
  static const _dbName = 'nexo_schedules.db';
  static const _table = 'schedules';
  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          professionalProfileId TEXT,
          dayOfWeek TEXT,
          startTime TEXT,
          endTime TEXT
        )
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertSchedules(List<AvailableSchedule> schedules) async {
    final db = await _openDb();
    final batch = db.batch();
    for (var s in schedules) {
      batch.insert(
        _table,
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AvailableSchedule>> getSchedules() async {
    final db = await _openDb();
    final maps = await db.query(_table);
    return maps.map((m) => AvailableSchedule.fromMap(m)).toList();
  }

  Future<void> replaceSchedules(List<AvailableSchedule> schedules) async {
    final db = await _openDb();
    await db.delete(_table);
    final batch = db.batch();
    for (var s in schedules) {
      batch.insert(
        _table,
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearSchedules() async {
    final db = await _openDb();
    await db.delete(_table);
  }
}
