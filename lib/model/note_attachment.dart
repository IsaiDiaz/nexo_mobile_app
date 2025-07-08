// lib/model/note_attachment.dart

// Represents a local note attachment (image, audio, etc.)
class NoteAttachment {
  final int? id; // Local DB ID
  final int noteId; // Foreign key to LocalNote's local DB ID
  final String filePathLocal; // Path on device's file system
  final String fileName;
  final String fileType; // e.g., 'image/jpeg', 'audio/aac'

  NoteAttachment({
    this.id,
    required this.noteId,
    required this.filePathLocal,
    required this.fileName,
    required this.fileType,
  });

  // Convert a NoteAttachment into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'file_path_local': filePathLocal,
      'file_name': fileName,
      'file_type': fileType,
    };
  }

  // Convert a Map (from SQLite) into a NoteAttachment object
  factory NoteAttachment.fromMap(Map<String, dynamic> map) {
    return NoteAttachment(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      filePathLocal: map['file_path_local'] as String,
      fileName: map['file_name'] as String,
      fileType: map['file_type'] as String,
    );
  }

  NoteAttachment copyWith({
    int? id,
    int? noteId,
    String? filePathLocal,
    String? fileName,
    String? fileType,
  }) {
    return NoteAttachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      filePathLocal: filePathLocal ?? this.filePathLocal,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
    );
  }

  @override
  String toString() {
    return 'NoteAttachment{id: $id, noteId: $noteId, fileName: $fileName, type: $fileType}';
  }
}
