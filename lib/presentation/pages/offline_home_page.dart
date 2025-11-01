import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/local/session_local.dart';
import 'package:nexo/presentation/widgets/professional_notes_sheet.dart';

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
            appBar: AppBar(title: const Text('Modo sin conexión')),
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
              if (roleStr.contains('PROFESSIONAL') ||
                  roleStr.contains('professional') ||
                  roleStr.contains('PROFESIONAL'))
                _OfflineNotesCard(),
              const SizedBox(height: 12),
              _OfflineAgendaCard(),
            ],
          ),
        );
      },
    );
  }
}

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
              'Puedes crear/editar notas locales asociadas a una cita específica. '
              'Estos cambios se guardan solo en el dispositivo.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.note_add),
              label: const Text('Abrir notas'),
              onPressed: () {
                // Abre el bottom sheet de notas locales.
                // Pide un ID de cita o muéstralo con UI propia. Aquí un ejemplo simple:
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

class _OfflineAgendaCard extends StatelessWidget {
  const _OfflineAgendaCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agenda (solo lectura)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Aquí puedes mostrar una agenda cacheada localmente si implementas '
              'un repositorio de citas offline. Por ahora se muestra un placeholder.',
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Citas próximas'),
              subtitle: const Text('Sincroniza online para actualizar.'),
              trailing: const Icon(Icons.lock),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Agenda offline aún no implementada (placeholder)',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
