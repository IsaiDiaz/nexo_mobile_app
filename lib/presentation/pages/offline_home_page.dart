import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/local/session_local.dart';
import 'package:nexo/presentation/app.dart';
import 'package:nexo/presentation/widgets/professional_notes_sheet.dart';
import 'package:nexo/data/local/local_appointment_repository.dart';
import 'package:nexo/data/local/local_appointment_type_repository.dart';
import 'package:nexo/data/local/local_schedule_repository.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/model/available_schedule.dart';
import 'package:nexo/data/auth_offline_repository.dart';
import 'package:nexo/application/auth_controller.dart';

class OfflineHomePage extends ConsumerWidget {
  const OfflineHomePage({super.key});

  Future<Map<String, dynamic>?> _loadLocalSession() async {
    return await LocalSessionRepository().getSession();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadLocalSession(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snap.data;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Modo sin conexión'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión offline',
                  onPressed: () async {
                    final container = ProviderScope.containerOf(
                      context,
                      listen: false,
                    );

                    await container
                        .read(authControllerProvider.notifier)
                        .signOut();
                  },
                ),
              ],
            ),
            body: const Center(
              child: Text('No hay sesión local. Inicia sesión online primero.'),
            ),
          );
        }

        final name = session['name'] ?? '';
        final email = session['email'] ?? '';
        final roleStr = session['role'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Modo sin conexión'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión offline',
                onPressed: () async {
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );

                  await container
                      .read(authControllerProvider.notifier)
                      .signOut();
                  container.read(offlineModeProvider.notifier).state = false;

                  container.read(authControllerProvider.notifier).state =
                      AuthState.unauthenticated;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión cerrada.')),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: const Text('Solo lectura'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Estás en modo sin conexión'),
                  subtitle: Text(
                    'Puedes ver la última información disponible en el dispositivo.\n'
                    'Para sincronizar cambios con el servidor, inicia sesión con conexión.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (roleStr.toUpperCase().contains('PROFESIONAL'))
                const _OfflineNotesCard(),
              const SizedBox(height: 12),
              const _OfflineAgendaCard(),
              const SizedBox(height: 12),
              const _OfflineAppointmentTypesCard(),
              const SizedBox(height: 12),
              const _OfflineSchedulesCard(),
            ],
          ),
        );
      },
    );
  }
}

/// 🔸 Notas locales
class _OfflineNotesCard extends StatelessWidget {
  const _OfflineNotesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notas locales (Profesional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes crear o editar notas asociadas a una cita específica. '
              'Los cambios se guardan solo en el dispositivo.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.note_add),
              label: const Text('Abrir notas'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const _AskAppointmentAndOpenNotes(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AskAppointmentAndOpenNotes extends StatefulWidget {
  const _AskAppointmentAndOpenNotes();

  @override
  State<_AskAppointmentAndOpenNotes> createState() =>
      _AskAppointmentAndOpenNotesState();
}

class _AskAppointmentAndOpenNotesState
    extends State<_AskAppointmentAndOpenNotes> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          children: [
            Text(
              'Abrir notas por ID de cita',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'ID de cita (appointment_id)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  final apptId = ctrl.text.trim();
                  if (apptId.isEmpty) return;
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ProfessionalNotesSheet(
                      appointmentId: apptId,
                      clientName: 'Cliente (offline)',
                    ),
                  );
                },
                child: const Text('Abrir notas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔸 Citas locales (Agenda)
class _OfflineAgendaCard extends StatelessWidget {
  const _OfflineAgendaCard();

  Future<List<Appointment>> _loadAppointments() async {
    final repo = LocalAppointmentRepository();
    return await repo.getAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Appointment>>(
      future: _loadAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agenda (sin datos)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No hay citas guardadas localmente.\n'
                    'Inicia sesión online para sincronizar.',
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Citas guardadas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: appointments.length,
                  itemBuilder: (ctx, i) {
                    final a = appointments[i];
                    // 👇 Usa 'type' si tu modelo no tiene 'service'
                    final serviceName = a.type ?? 'Sin tipo';
                    final startTime = a.start.toString().split('.')[0];
                    final endTime = a.end.toString().split('.')[0];
                    return ListTile(
                      leading: const Icon(Icons.event_note),
                      title: Text(serviceName),
                      subtitle: Text('${a.status} | $startTime → $endTime'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🔸 Tipos de cita locales
class _OfflineAppointmentTypesCard extends StatelessWidget {
  const _OfflineAppointmentTypesCard();

  Future<List<Map<String, dynamic>>> _loadAppointmentTypes() async {
    final repo = LocalAppointmentTypeRepository();
    return await repo.getAppointmentTypes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadAppointmentTypes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final types = snapshot.data ?? [];
        if (types.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipos de cita guardados',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...types.map(
                  (t) => ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(t['name'] ?? 'Tipo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🔸 Horarios locales
class _OfflineSchedulesCard extends StatelessWidget {
  const _OfflineSchedulesCard();

  Future<List<AvailableSchedule>> _loadSchedules() async {
    final repo = LocalScheduleRepository();
    return await repo.getSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<AvailableSchedule>>(
      future: _loadSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final schedules = snapshot.data ?? [];
        if (schedules.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horarios disponibles',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...schedules.map(
                  (s) => ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text('${s.dayOfWeek.toUpperCase()}'),
                    subtitle: Text(
                      '${s.formattedStartTime} → ${s.formattedEndTime}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
