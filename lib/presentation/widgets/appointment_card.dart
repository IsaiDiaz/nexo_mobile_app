import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const AppointmentCard({super.key, required this.appointment});

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

    final professionalName =
        appointment.professionalRecord?.get<String?>('expand.user.name') ??
        appointment.professionalRecord?.get<String?>('name') ??
        'Profesional Desconocido';
    final professionalCategory =
        appointment.professionalRecord?.get<String?>('category') ??
        'No especificada';

    final dateFormat = DateFormat('EEEE, d MMMM y', 'es');
    final timeFormat = DateFormat('HH:mm', 'es');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cita con: $professionalName',
              style: theme.textTheme.titleLarge?.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo de Servicio: ${appointment.type ?? 'N/A'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Categoría: $professionalCategory',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: secondaryTextColor),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(appointment.start),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: secondaryTextColor),
                const SizedBox(width: 8),
                Text(
                  '${timeFormat.format(appointment.start)} - ${timeFormat.format(appointment.end)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            //mostrar appointment.comments
            if (appointment.comments != null &&
                appointment.comments!.trim().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentarios:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.comments!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado: ${appointment.status}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _getStatusColor(
                      appointment.status,
                      theme.colorScheme,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'Confirmada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      case 'Completada':
        return colorScheme.primary;
      default:
        return Colors.grey;
    }
  }
}
