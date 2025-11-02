import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:nexo/model/appointment.dart';

class LocalAppointmentRepository {
  static const _dbName = 'nexo_appointments.db';
  static const _table = 'appointments';
  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      path,
      version: 2, // ⚠️ Incrementa versión para forzar recreación
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          professionalProfileId TEXT,
          clientId TEXT,
          type TEXT,
          comments TEXT,
          originalFee REAL DEFAULT 0.0,
          discountFee REAL DEFAULT 0.0,
          status TEXT,
          start TEXT,
          end TEXT
        )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ⚠️ Si el esquema cambió, recrea la tabla
        await db.execute('DROP TABLE IF EXISTS $_table');
        await db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          professionalProfileId TEXT,
          clientId TEXT,
          type TEXT,
          comments TEXT,
          originalFee REAL DEFAULT 0.0,
          discountFee REAL DEFAULT 0.0,
          status TEXT,
          start TEXT,
          end TEXT
        )
        ''');
      },
    );

    return _db!;
  }

  Future<void> insertAppointments(List<Appointment> appointments) async {
    final db = await _openDb();
    final batch = db.batch();
    for (var a in appointments) {
      batch.insert(
        _table,
        a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Appointment>> getAppointments() async {
    final db = await _openDb();
    final maps = await db.query(_table);
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<void> replaceAppointments(List<Appointment> appointments) async {
    final db = await _openDb();
    await db.delete(_table);
    final batch = db.batch();
    for (var a in appointments) {
      batch.insert(
        _table,
        a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAppointments() async {
    final db = await _openDb();
    await db.delete(_table);
  }
}
