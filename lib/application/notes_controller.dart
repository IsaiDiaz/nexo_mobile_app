import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/local_note_repository.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/local_note.dart';
import 'package:nexo/model/note_attachment.dart';
import 'package:path/path.dart' as p;

class NotesState {
  final List<LocalNote> notes;
  final bool isLoading;
  final String? errorMessage;

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
  // ignore: unused_field
  final AuthRepository _authRepository;
  final Ref _ref;

  NotesController(this._localNotesRepository, this._authRepository, this._ref)
    : super(NotesState(notes: []));

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

      await loadNotesForAppointment(appointmentId);
      _ref.invalidate(appointmentNotesProvider(appointmentId));

      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al añadir nota: $e',
      );
      return 'Error al añadir nota: $e';
    }
  }

  Future<String?> deleteNote(LocalNote note, String appointmentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _localNotesRepository.deleteNote(note.id!);
      await loadNotesForAppointment(appointmentId);
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
        return 'application/octet-stream';
    }
  }
}

final notesControllerProvider =
    StateNotifierProvider<NotesController, NotesState>((ref) {
      final localNotesRepo = ref.watch(localNotesRepositoryProvider);
      final authRepo = ref.watch(authRepositoryProvider);
      return NotesController(localNotesRepo, authRepo, ref);
    });

final appointmentNotesProvider =
    FutureProvider.family<Map<LocalNote, List<NoteAttachment>>, String>((
      ref,
      appointmentId,
    ) async {
      final notesRepo = ref.read(localNotesRepositoryProvider);

      final notes = await notesRepo.getNotesForAppointment(appointmentId);
      final Map<LocalNote, List<NoteAttachment>> notesWithAttachments = {};
      for (var note in notes) {
        final attachments = await notesRepo.getAttachmentsForNote(note.id!);
        notesWithAttachments[note] = attachments;
      }
      return notesWithAttachments;
    });
