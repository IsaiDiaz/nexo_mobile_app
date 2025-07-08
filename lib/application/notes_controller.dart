// lib/application/notes_controller.dart

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/local_note_repository.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/local_note.dart';
import 'package:nexo/model/note_attachment.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class NotesState {
  final List<LocalNote> notes;
  final bool isLoading;
  final String? errorMessage;
  // Removed isSyncing for local-only

  NotesState({required this.notes, this.isLoading = false, this.errorMessage});

  NotesState copyWith({
    List<LocalNote>? notes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotesController extends StateNotifier<NotesState> {
  final LocalNotesRepository _localNotesRepository;
  final AuthRepository _authRepository; // Still needed to get professional ID
  final Ref _ref; // Still needed to get current user

  NotesController(this._localNotesRepository, this._authRepository, this._ref)
    : super(NotesState(notes: []));

  // Carga las notas para una cita específica desde la DB local
  Future<void> loadNotesForAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notes = await _localNotesRepository.getNotesForAppointment(
        appointmentId,
      );
      state = state.copyWith(isLoading: false, notes: notes);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar notas: $e',
      );
    }
  }

  // Añade una nueva nota localmente
  Future<String?> addNote(
    String appointmentId,
    String noteText,
    List<String> attachmentLocalPaths,
  ) async {
    final currentUser = _ref.read(currentUserRecordProvider);
    if (currentUser == null) {
      return 'No se pudo identificar al profesional para añadir la nota.';
    }
    final professionalId = currentUser.id;

    // state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final now = DateTime.now();
      final newNote = LocalNote(
        appointmentId: appointmentId,
        professionalId: professionalId,
        noteText: noteText,
        createdAt: now,
        lastModifiedAt: now,
      );

      final noteId = await _localNotesRepository.insertNote(newNote);
      if (noteId == 0) {
        return 'Error al guardar la nota localmente.';
      }

      // Guardar adjuntos
      for (var path in attachmentLocalPaths) {
        final fileName = p.basename(path);
        final fileType = _getFileTypeFromPath(path);
        await _localNotesRepository.insertAttachment(
          NoteAttachment(
            noteId: noteId,
            filePathLocal: path,
            fileName: fileName,
            fileType: fileType,
          ),
        );
      }

      // Recargar las notas para la UI
      await loadNotesForAppointment(appointmentId);
      _ref.invalidate(appointmentNotesProvider(appointmentId));

      return null; // Éxito
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al añadir nota: $e',
      );
      return 'Error al añadir nota: $e';
    }
  }

  // Elimina una nota localmente
  Future<String?> deleteNote(LocalNote note, String appointmentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _localNotesRepository.deleteNote(note.id!);
      await loadNotesForAppointment(appointmentId); // Recargar
      _ref.invalidate(appointmentNotesProvider(appointmentId));

      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar nota: $e',
      );
      return 'Error al eliminar nota: $e';
    }
  }

  // Removed _syncNotes() and _startPeriodicSync() for local-only implementation

  // Helper para obtener el tipo de archivo (MIME) de una ruta
  String _getFileTypeFromPath(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.mp3':
        return 'audio/mpeg';
      case '.aac':
        return 'audio/aac';
      case '.m4a':
        return 'audio/m4a';
      default:
        return 'application/octet-stream'; // Tipo genérico
    }
  }
}

final notesControllerProvider =
    StateNotifierProvider<NotesController, NotesState>((ref) {
      final localNotesRepo = ref.watch(localNotesRepositoryProvider);
      final authRepo = ref.watch(authRepositoryProvider);
      return NotesController(localNotesRepo, authRepo, ref);
    });

// Proveedor para obtener las notas y adjuntos de una cita específica (para la UI)
final appointmentNotesProvider =
    FutureProvider.family<Map<LocalNote, List<NoteAttachment>>, String>((
      ref,
      appointmentId,
    ) async {
      // No necesitas watch() aquí si tu NotesController NO mantiene un mapa global de todas las notas.
      // Si tu NotesController solo maneja la lista de la cita actual, entonces este FutureProvider
      // debe ser el que va directamente al repositorio.
      final notesRepo = ref.read(localNotesRepositoryProvider);

      // Es importante que la UI muestre el estado de carga y error de este FutureProvider.
      // El NotesState del NotesController solo refleja el estado de sus *propias* operaciones.

      final notes = await notesRepo.getNotesForAppointment(appointmentId);
      final Map<LocalNote, List<NoteAttachment>> notesWithAttachments = {};
      for (var note in notes) {
        final attachments = await notesRepo.getAttachmentsForNote(note.id!);
        notesWithAttachments[note] = attachments;
      }
      return notesWithAttachments;
    });
