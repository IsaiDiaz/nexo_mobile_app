import 'package:flutter/foundation.dart';

class LocalNote {
  final int? id;
  final String appointmentId;
  final String professionalId;
  final String noteText;
  final DateTime createdAt;
  final DateTime lastModifiedAt;

  LocalNote({
    this.id,
    required this.appointmentId,
    required this.professionalId,
    required this.noteText,
    required this.createdAt,
    required this.lastModifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'professional_id': professionalId,
      'note_text': noteText,
      'created_at': createdAt.toIso8601String(),
      'last_modified_at': lastModifiedAt.toIso8601String(),
    };
  }

  factory LocalNote.fromMap(Map<String, dynamic> map) {
    return LocalNote(
      id: map['id'] as int?,
      appointmentId: map['appointment_id'] as String,
      professionalId: map['professional_id'] as String,
      noteText: map['note_text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModifiedAt: DateTime.parse(map['last_modified_at'] as String),
    );
  }

  LocalNote copyWith({
    int? id,
    String? appointmentId,
    String? professionalId,
    String? noteText,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
  }) {
    return LocalNote(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      professionalId: professionalId ?? this.professionalId,
      noteText: noteText ?? this.noteText,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return 'LocalNote{id: $id, appointmentId: $appointmentId, noteText: $noteText}';
  }
}
