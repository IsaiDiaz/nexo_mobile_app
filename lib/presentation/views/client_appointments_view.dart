import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nexo/application/appointment_controller.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/presentation/widgets/appointment_card.dart';

class ClientAppointmentsView extends ConsumerWidget {
  const ClientAppointmentsView({super.key});

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

    final appointmentState = ref.watch(appointmentControllerProvider);

    if (appointmentState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando tus citas...',
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

    final upcomingAppointments = ref.watch(clientUpcomingAppointmentsProvider);
    final completedAppointments = ref.watch(
      clientCompletedAppointmentsProvider,
    );

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: primaryTextColor,
            unselectedLabelColor: secondaryTextColor,
            indicatorColor: primaryTextColor,
            tabs: const [
              Tab(text: 'Próximas'),
              Tab(text: 'Historial'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAppointmentsList(
                  context,
                  upcomingAppointments,
                  'No tienes citas próximas o pendientes.',
                  isDarkMode,
                ),
                _buildAppointmentsList(
                  context,
                  completedAppointments,
                  'No tienes citas en tu historial.',
                  isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    List<Appointment> appointments,
    String emptyMessage,
    bool isDarkMode,
  ) {
    if (appointments.isEmpty) {
      final theme = Theme.of(context);
      final secondaryTextColor = isDarkMode
          ? DarkAppColors.secondaryText
          : LightAppColors.secondaryText;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            emptyMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(appointment: appointment);
      },
    );
  }
}
