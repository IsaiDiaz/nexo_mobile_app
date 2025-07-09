import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/model/local_note.dart';
import 'package:nexo/model/note_attachment.dart';

class LocalNotesRepository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    path = join(path, 'nexo_notes.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE consultation_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id TEXT NOT NULL,
        professional_id TEXT NOT NULL,
        note_text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_modified_at TEXT NOT NULL
        -- Removed sync_status and pocketbase_record_id for local-only
      )
    ''');
    await db.execute('''
      CREATE TABLE note_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        file_path_local TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        -- Removed sync_status, uploaded_url, pocketbase_file_id for local-only
        FOREIGN KEY (note_id) REFERENCES consultation_notes(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertNote(LocalNote note) async {
    final db = await database;
    return await db.insert(
      'consultation_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(LocalNote note) async {
    final db = await database;
    await db.update(
      'consultation_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<LocalNote?> getNoteById(int noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consultation_notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
    if (maps.isNotEmpty) {
      return LocalNote.fromMap(maps.first);
    }
    return null;
  }

  Future<List<LocalNote>> getNotesForAppointment(String appointmentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consultation_notes',
      where: 'appointment_id = ?',
      whereArgs: [appointmentId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => LocalNote.fromMap(maps[i]));
  }

  Future<void> deleteNote(int noteId) async {
    final db = await database;
    await db.delete('consultation_notes', where: 'id = ?', whereArgs: [noteId]);
  }

  Future<int> insertAttachment(NoteAttachment attachment) async {
    final db = await database;
    return await db.insert(
      'note_attachments',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAttachment(NoteAttachment attachment) async {
    final db = await database;
    await db.update(
      'note_attachments',
      attachment.toMap(),
      where: 'id = ?',
      whereArgs: [attachment.id],
    );
  }

  Future<List<NoteAttachment>> getAttachmentsForNote(int noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'note_attachments',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'file_name ASC',
    );
    return List.generate(maps.length, (i) => NoteAttachment.fromMap(maps[i]));
  }

  Future<void> deleteAttachment(int attachmentId) async {
    final db = await database;
    await db.delete(
      'note_attachments',
      where: 'id = ?',
      whereArgs: [attachmentId],
    );
  }
}

final localNotesRepositoryProvider = Provider((ref) => LocalNotesRepository());
