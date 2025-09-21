import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nexo/application/appointment_controller.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/presentation/widgets/professional_notes_sheet.dart';
import 'package:nexo/presentation/widgets/add_manual_appointmnet_sheet.dart';

class ProfessionalAppointmentsView extends ConsumerWidget {
  const ProfessionalAppointmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final appointmentState = ref.watch(appointmentControllerProvider);

    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);

    if (appointmentState.isLoading && appointmentState.appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando citas...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (appointmentState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${appointmentState.errorMessage}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    if (upcomingAppointments.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddManualAppointmentSheet(),
            );
          },

          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Text(
            'No tienes citas próximas.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final Map<DateTime, List<Appointment>> groupedByDate = {};
    for (var appointment in upcomingAppointments) {
      final dateOnly = DateTime(
        appointment.start.year,
        appointment.start.month,
        appointment.start.day,
      );
      groupedByDate.putIfAbsent(dateOnly, () => []).add(appointment);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddManualAppointmentSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedDates.length,
        itemBuilder: (context, dateIndex) {
          final date = sortedDates[dateIndex];
          final appointmentsOnDate = groupedByDate[date]!
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
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...appointmentsOnDate.map((appointment) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: cardColor,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cliente: ${appointment.clientName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Servicio: ${appointment.type}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          'Hora: ${appointment.formattedStartTime} - ${appointment.formattedEndTime}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          'Comentarios: ${appointment.comments == null || appointment.comments!.isEmpty ? 'Ninguno' : appointment.comments}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          'Estado: ${appointment.status}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _getStatusColor(
                              appointment.status,
                              isDarkMode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (appointment.status == 'Pendiente') ...[
                              ElevatedButton(
                                onPressed: () => _updateStatus(
                                  ref,
                                  appointment.id,
                                  'Confirmada',
                                  context,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: primaryTextColor,
                                ),
                                child: const Text('Confirmar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateStatus(
                                  ref,
                                  appointment.id,
                                  'Rechazada',
                                  context,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: primaryTextColor,
                                ),
                                child: const Text('Rechazar'),
                              ),
                            ],
                            if (appointment.status == 'Confirmada') ...[
                              ElevatedButton(
                                onPressed: () => _updateStatus(
                                  ref,
                                  appointment.id,
                                  'Cancelada',
                                  context,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: primaryTextColor,
                                ),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showNotesModal(
                                    context,
                                    ref,
                                    appointment.id,
                                    appointment.clientName,
                                  );
                                },
                                icon: const Icon(Icons.notes, size: 18),
                                label: const Text('Notas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: primaryTextColor,
                                ),
                              ),
                            ],
                            if (appointment.status == 'Rechazada')
                              ElevatedButton(
                                onPressed: () => _deleteAppointment(
                                  ref,
                                  appointment.id,
                                  context,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: primaryTextColor,
                                ),
                                child: const Text('Eliminar'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
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

  void _updateStatus(
    WidgetRef ref,
    String appointmentId,
    String newStatus,
    BuildContext context,
  ) async {
    final errorMessage = await ref
        .read(appointmentControllerProvider.notifier)
        .updateAppointmentStatus(appointmentId, newStatus);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $errorMessage')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cita actualizada a "$newStatus".')),
      );
    }
  }

  void _deleteAppointment(
    WidgetRef ref,
    String appointmentId,
    BuildContext context,
  ) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Cita'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta cita? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      final errorMessage = await ref
          .read(appointmentControllerProvider.notifier)
          .deleteAppointment(appointmentId);

      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cita: $errorMessage')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita eliminada exitosamente.')),
        );
      }
    }
  }

  void _showNotesModal(
    BuildContext context,
    WidgetRef ref,
    String appointmentId,
    String clientName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ProfessionalNotesSheet(
          appointmentId: appointmentId,
          clientName: clientName,
        );
      },
    ).whenComplete(() {
      ref.invalidate(upcomingAppointmentsProvider);
    });
  }
}
