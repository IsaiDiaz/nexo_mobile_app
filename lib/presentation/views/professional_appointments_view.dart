// lib/presentation/views/professional_appointments_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:nexo/application/professional_appointment_controller.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/presentation/widgets/manage_appointment_types_sheet.dart';
import 'package:nexo/presentation/widgets/professional_notes_sheet.dart';
import 'package:nexo/presentation/widgets/add_manual_appointmnet_sheet.dart';

class ProfessionalAppointmentsView extends ConsumerWidget {
  const ProfessionalAppointmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryText = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryText = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final cardColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    final state = ref.watch(professionalAppointmentControllerProvider);
    final upcoming = ref.watch(professionalUpcomingAppointmentsProvider);

    if (state.isLoading && state.appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando citas...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${state.errorMessage}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    if (upcoming.isEmpty) {
      return Scaffold(
        floatingActionButton: GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const ManageAppointmentTypesSheet(),
            );
          },
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddManualAppointmentSheet(),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
        body: Center(
          child: Text(
            'No tienes citas próximas.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final Map<DateTime, List<Appointment>> grouped = {};
    for (final a in upcoming) {
      final d = DateTime(a.start.year, a.start.month, a.start.day);
      grouped.putIfAbsent(d, () => []).add(a);
    }
    final dates = grouped.keys.toList()..sort();

    return Scaffold(
      floatingActionButton: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ManageAppointmentTypesSheet(),
          );
        },
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddManualAppointmentSheet(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dates.length,
        itemBuilder: (_, i) {
          final date = dates[i];
          final items = grouped[date]!
            ..sort((a, b) => a.start.compareTo(b.start));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
                child: Text(
                  DateFormat('EEEE, d MMMM y', 'es').format(date),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...items!.map(
                (a) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: cardColor,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _AppointmentRow(
                      appointment: a,
                      isDarkMode: isDarkMode,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      onUpdateStatus: (status) =>
                          _updateStatus(ref, a.id, status, context),
                      onDelete: () => _deleteAppointment(ref, a.id, context),
                      onNotes: () =>
                          _showNotesModal(context, ref, a.id, a.clientName),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(String s, bool dark) {
    switch (s) {
      case 'Pendiente':
        return dark ? Colors.orange[300]! : Colors.orange[700]!;
      case 'Confirmada':
        return dark ? Colors.green[300]! : Colors.green[700]!;
      case 'Rechazada':
      case 'Cancelada':
        return dark ? Colors.red[300]! : Colors.red[700]!;
      default:
        return dark
            ? DarkAppColors.secondaryText
            : LightAppColors.secondaryText;
    }
  }

  Future<void> _updateStatus(
    WidgetRef ref,
    String id,
    String status,
    BuildContext ctx,
  ) async {
    final err = await ref
        .read(professionalAppointmentControllerProvider.notifier)
        .updateAppointmentStatus(id, status);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          err != null
              ? 'Error al actualizar estado: $err'
              : 'Cita actualizada a "$status".',
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(
    WidgetRef ref,
    String id,
    BuildContext ctx,
  ) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta cita? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final err = await ref
          .read(professionalAppointmentControllerProvider.notifier)
          .deleteAppointment(id);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            err != null
                ? 'Error al eliminar cita: $err'
                : 'Cita eliminada exitosamente.',
          ),
        ),
      );
    }
  }

  void _showNotesModal(
    BuildContext context,
    WidgetRef ref,
    String apptId,
    String clientName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          ProfessionalNotesSheet(appointmentId: apptId, clientName: clientName),
    ).whenComplete(() {
      // Recargar profesional al cerrar el sheet de notas
      ref
          .read(professionalAppointmentControllerProvider.notifier)
          .loadProfessionalAppointments();
    });
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    required this.isDarkMode,
    required this.primaryText,
    required this.secondaryText,
    required this.onUpdateStatus,
    required this.onDelete,
    required this.onNotes,
  });

  final Appointment appointment;
  final bool isDarkMode;
  final Color primaryText;
  final Color secondaryText;
  final void Function(String newStatus) onUpdateStatus;
  final VoidCallback onDelete;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color _statusColor(String s) {
      switch (s) {
        case 'Pendiente':
          return isDarkMode ? Colors.orange[300]! : Colors.orange[700]!;
        case 'Confirmada':
          return isDarkMode ? Colors.green[300]! : Colors.green[700]!;
        case 'Rechazada':
        case 'Cancelada':
          return isDarkMode ? Colors.red[300]! : Colors.red[700]!;
        default:
          return isDarkMode
              ? DarkAppColors.secondaryText
              : LightAppColors.secondaryText;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente: ${appointment.clientName}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Servicio: ${appointment.type}',
          style: theme.textTheme.bodyLarge?.copyWith(color: secondaryText),
        ),
        Text(
          'Hora: ${appointment.formattedStartTime} - ${appointment.formattedEndTime}',
          style: theme.textTheme.bodyLarge?.copyWith(color: secondaryText),
        ),
        Text(
          'Comentarios: ${appointment.comments == null || appointment.comments!.isEmpty ? 'Ninguno' : appointment.comments}',
          style: theme.textTheme.bodyLarge?.copyWith(color: secondaryText),
        ),
        Text(
          'Estado: ${appointment.status}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _statusColor(appointment.status),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (appointment.status == 'Pendiente') ...[
              ElevatedButton(
                onPressed: () => onUpdateStatus('Confirmada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: primaryText,
                ),
                child: const Text('Confirmar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onUpdateStatus('Rechazada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: primaryText,
                ),
                child: const Text('Rechazar'),
              ),
            ],
            if (appointment.status == 'Confirmada') ...[
              ElevatedButton(
                onPressed: () => onUpdateStatus('Cancelada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: primaryText,
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onNotes,
                icon: const Icon(Icons.notes, size: 18),
                label: const Text('Notas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: primaryText,
                ),
              ),
            ],
            if (appointment.status == 'Rechazada')
              ElevatedButton(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: primaryText,
                ),
                child: const Text('Eliminar'),
              ),
          ],
        ),
      ],
    );
  }
}
