// lib/model/local_note.dart

import 'package:flutter/foundation.dart';

class LocalNote {
  final int? id; // Local DB ID
  final String
  appointmentId; // PocketBase Appointment ID (still needed to link to the appointment displayed)
  final String
  professionalId; // PocketBase Professional ID (still needed to identify who wrote the note)
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

  // Convert a LocalNote into a Map for SQLite
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

  // Convert a Map (from SQLite) into a LocalNote object
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

  // Helper to create a copy with updated values
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
