// lib/presentation/views/client_appointments_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/client_appointment_controller.dart';
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

    final state = ref.watch(clientAppointmentControllerProvider);

    if (state.isLoading && state.appointments.isEmpty) {
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

    final upcoming = ref.watch(clientUpcomingAppointmentsProvider);
    final completed = ref.watch(clientCompletedAppointmentsProvider);

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
                _buildList(
                  context,
                  upcoming,
                  'No tienes citas próximas o pendientes.',
                  isDarkMode,
                ),
                _buildList(
                  context,
                  completed,
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

  Widget _buildList(
    BuildContext context,
    List<Appointment> items,
    String empty,
    bool isDark,
  ) {
    if (items.isEmpty) {
      final theme = Theme.of(context);
      final secondary = isDark
          ? DarkAppColors.secondaryText
          : LightAppColors.secondaryText;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            empty,
            style: theme.textTheme.bodyLarge?.copyWith(color: secondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (_, i) => AppointmentCard(appointment: items[i]),
    );
  }
}
