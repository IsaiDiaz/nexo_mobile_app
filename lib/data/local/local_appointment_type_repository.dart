import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalAppointmentTypeRepository {
  static const _dbName = 'nexo_appointment_types.db';
  static const _table = 'appointment_types';
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
          professionalId TEXT,
          name TEXT
        )
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertAppointmentTypes(List<Map<String, dynamic>> types) async {
    final db = await _openDb();
    final batch = db.batch();
    for (var t in types) {
      batch.insert(_table, t, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getAppointmentTypes() async {
    final db = await _openDb();
    return await db.query(_table);
  }

  Future<void> replaceAppointmentTypes(List<Map<String, dynamic>> types) async {
    final db = await _openDb();
    await db.delete(_table);
    final batch = db.batch();
    for (var t in types) {
      batch.insert(_table, t, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAppointmentTypes() async {
    final db = await _openDb();
    await db.delete(_table);
  }
}
