import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalSessionRepository {
  // Singleton
  static final LocalSessionRepository _instance =
      LocalSessionRepository._internal();
  factory LocalSessionRepository() => _instance;
  LocalSessionRepository._internal();

  static Database? _db;
  static const _dbName = 'nexo_auth.db';
  static const _tableName = 'session';

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    print('📦 Abriendo base de datos en: $path');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        // Forzamos modo WAL para mejor consistencia
        await db.rawQuery('PRAGMA journal_mode=WAL;');
      },
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL,
        email TEXT NOT NULL,
        name TEXT,
        role TEXT,
        jwt_token TEXT,
        jwt_expires_at INTEGER,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');
    print('🆕 Tabla session creada en SQLite');
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    final db = await database;
    print("💾 Guardando sesión en SQLite: $data");

    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final check = await db.query(_tableName);
    print("📂 Sesión en DB tras guardar: $check");
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await database;
    final result = await db.query(_tableName, where: 'id = 1');
    print("📥 Resultado SQLite getSession(): $result");
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete(_tableName);
    print('🧹 Sesión SQLite eliminada');
  }
}
