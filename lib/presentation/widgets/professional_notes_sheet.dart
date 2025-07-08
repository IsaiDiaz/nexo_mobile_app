import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexo/application/notes_controller.dart';
import 'package:nexo/model/note_attachment.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart'; // Para formatear fechas más bonitas
import 'package:nexo/presentation/theme/app_colors.dart';

class ProfessionalNotesSheet extends ConsumerStatefulWidget {
  final String appointmentId;
  final String clientName;

  const ProfessionalNotesSheet({
    super.key,
    required this.appointmentId,
    required this.clientName,
  });

  @override
  ConsumerState<ProfessionalNotesSheet> createState() =>
      _ProfessionalNotesSheetState();
}

class _ProfessionalNotesSheetState
    extends ConsumerState<ProfessionalNotesSheet> {
  final TextEditingController _noteTextController = TextEditingController();
  final List<String> _attachmentPaths = [];

  final ImagePicker _picker = ImagePicker();
  String? _audioFilePath;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // _loadExistingNotes();
  }

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  void _loadExistingNotes() {
    ref
        .read(notesControllerProvider.notifier)
        .loadNotesForAppointment(widget.appointmentId);
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request permissions more granularly as per Android 13+ guidelines
    final status = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();

    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachmentPaths.add(image.path);
        });
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permiso de ${source == ImageSource.camera ? 'cámara' : 'galería'} denegado.',
          ),
        ),
      );
    }
  }

  Future<void> _saveNote() async {
    if (_noteTextController.text.trim().isEmpty && _attachmentPaths.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nota no puede estar vacía.')),
      );
      return;
    }

    final errorMessage = await ref
        .read(notesControllerProvider.notifier)
        .addNote(
          widget.appointmentId,
          _noteTextController.text.trim(),
          _attachmentPaths,
        );

    if (!mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar nota: $errorMessage')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota guardada localmente.')),
      );
      _noteTextController.clear();
      setState(() {
        _attachmentPaths.clear();
      });

      ref.invalidate(appointmentNotesProvider(widget.appointmentId));
    }
  }

  void _removeAttachment(String path) {
    setState(() {
      _attachmentPaths.remove(path);
      // Opcional: Eliminar el archivo físico si ya no se necesita
      // File(path).delete(); // Ten cuidado con esto si el archivo podría ser referenciado por otras notas temporales
    });
  }

  // Helper para mostrar miniaturas de adjuntos (imágenes y audio)
  Widget _buildAttachmentThumbnail(NoteAttachment attachment) {
    final isImage = attachment.fileType.startsWith('image/');
    final isAudio = attachment.fileType.startsWith('audio/');
    final theme = Theme.of(context);
    final secondaryTextColor = theme.brightness == Brightness.dark
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final primaryTextColor = theme.brightness == Brightness.dark
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;

    return GestureDetector(
      onTap: () {
        // Implementar visualizador de imágenes o reproductor de audio
        if (isImage) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Image.file(File(attachment.filePathLocal)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        } else if (isAudio) {
          // Implementar reproducción de audio
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reproduciendo ${attachment.fileName} (no implementado en UI)',
              ),
            ),
          );
          // Puedes usar un paquete como audioplayers para esto
        }
      },
      child: Chip(
        label: Text(attachment.fileName, overflow: TextOverflow.ellipsis),
        backgroundColor: secondaryTextColor.withOpacity(0.1),
        labelStyle: TextStyle(color: primaryTextColor),
        avatar: Icon(
          isImage
              ? Icons.image
              : (isAudio ? Icons.audiotrack : Icons.insert_drive_file),
          color: secondaryTextColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryTextColor = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final cardColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    final notesState = ref.watch(notesControllerProvider);
    final appointmentNotesAsync = ref.watch(
      appointmentNotesProvider(widget.appointmentId),
    );

    appointmentNotesAsync.when(
      data: (notesWithAttachments) {
        /* ... */
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Notas para ${widget.clientName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteTextController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Añadir nueva nota...',
                  hintStyle: TextStyle(
                    color: secondaryTextColor.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.all(16.0),
                ),
                style: TextStyle(color: primaryTextColor),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    color: theme.colorScheme.primary,
                    onPressed: () => _pickImage(ImageSource.camera),
                    tooltip: 'Tomar Foto',
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    color: theme.colorScheme.primary,
                    onPressed: () => _pickImage(ImageSource.gallery),
                    tooltip: 'Seleccionar de Galería',
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.send),
                    label: const Text('Guardar Nota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_attachmentPaths.isNotEmpty)
                Container(
                  height: 60, // Ajusta la altura si es necesario para los chips
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachmentPaths.length,
                    itemBuilder: (context, index) {
                      final path = _attachmentPaths[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Chip(
                          label: Text(
                            p.basename(path),
                            overflow: TextOverflow.ellipsis,
                          ),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _removeAttachment(path),
                          backgroundColor: secondaryTextColor.withOpacity(0.1),
                          labelStyle: TextStyle(color: primaryTextColor),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(),
              Text(
                'Historial de Notas:',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: appointmentNotesAsync.when(
                  data: (notesWithAttachments) {
                    if (notesWithAttachments.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay notas para esta cita.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      );
                    }
                    final sortedNotes = notesWithAttachments.keys.toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: sortedNotes.length,
                      itemBuilder: (context, index) {
                        final note = sortedNotes[index];
                        final attachments = notesWithAttachments[note]!;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                    'es',
                                  ).format(note.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.noteText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: primaryTextColor,
                                  ),
                                ),
                                // No mostramos estado de sincronización ya que es local-only
                                if (attachments.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Adjuntos:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: attachments.map((attachment) {
                                      return _buildAttachmentThumbnail(
                                        attachment,
                                      );
                                    }).toList(),
                                  ),
                                ],
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final bool?
                                      confirmDelete = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            title: const Text('Eliminar Nota'),
                                            content: const Text(
                                              '¿Estás seguro de eliminar esta nota y sus adjuntos?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  dialogContext,
                                                ).pop(false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  dialogContext,
                                                ).pop(true),
                                                child: const Text(
                                                  'Eliminar',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (confirmDelete == true) {
                                        final error = await ref
                                            .read(
                                              notesControllerProvider.notifier,
                                            )
                                            .deleteNote(
                                              note,
                                              widget.appointmentId,
                                            );
                                        if (error != null) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error al eliminar nota: $error',
                                              ),
                                            ),
                                          );
                                        } else {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Nota eliminada localmente.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error al cargar notas: $err',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
