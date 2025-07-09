class NoteAttachment {
  final int? id;
  final int noteId;
  final String filePathLocal;
  final String fileName;
  final String fileType;

  NoteAttachment({
    this.id,
    required this.noteId,
    required this.filePathLocal,
    required this.fileName,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'file_path_local': filePathLocal,
      'file_name': fileName,
      'file_type': fileType,
    };
  }

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
