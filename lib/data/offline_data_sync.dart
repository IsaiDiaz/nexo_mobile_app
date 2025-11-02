import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/data/appointment_repository.dart';
import 'package:nexo/data/local_note_repository.dart';
import 'package:nexo/data/schedule_repository.dart';
import 'package:nexo/data/appointment_type_repository.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/model/local_note.dart';
import 'package:nexo/model/available_schedule.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/data/local/local_appointment_repository.dart';
import 'package:nexo/data/local/local_schedule_repository.dart';
import 'package:nexo/data/local/local_appointment_type_repository.dart';

class OfflineDataSync {
  final Ref _ref;
  OfflineDataSync(this._ref);

  /// 🔁 Punto de entrada para sincronización general.
  Future<void> syncUserData() async {
    final user = _ref.read(currentUserRecordProvider);
    final role = _ref.read(activeRoleProvider);
    if (user == null || role == null) return;

    final appointmentRepo = _ref.read(appointmentRepositoryProvider);
    final notesRepo = _ref.read(localNotesRepositoryProvider);
    final scheduleRepo = _ref.read(scheduleRepositoryProvider);
    final appointmentTypeRepo = _ref.read(appointmentTypeRepositoryProvider);

    try {
      if (role == UserRole.client) {
        await _syncClientData(user.id, appointmentRepo, notesRepo);
      } else if (role == UserRole.professional) {
        await _syncProfessionalData(
          user.id,
          appointmentRepo,
          notesRepo,
          scheduleRepo,
          appointmentTypeRepo,
        );
      }
    } catch (e) {
      print("⚠️ Error al sincronizar datos offline: $e");
    }
  }

  // =====================================================
  // CLIENTE
  // =====================================================
  Future<void> _syncClientData(
    String userId,
    AppointmentRepository appointmentRepo,
    LocalNotesRepository notesRepo,
  ) async {
    print("🧠 Sincronizando datos cliente $userId");

    final appointments = await appointmentRepo.getAppointmentsForClient(userId);
    print("📥 ${appointments.length} citas cliente descargadas.");

    final localAppointmentRepo = LocalAppointmentRepository();
    await localAppointmentRepo.clearAppointments();
    await localAppointmentRepo.insertAppointments(appointments);
    for (var appt in appointments) {
      final notes = await notesRepo.getNotesForAppointment(appt.id);
      print("📝 ${notes.length} notas para cita ${appt.id}");
    }
  }

  // =====================================================
  // PROFESIONAL
  // =====================================================
  Future<void> _syncProfessionalData(
    String userId,
    AppointmentRepository appointmentRepo,
    LocalNotesRepository notesRepo,
    ScheduleRepository scheduleRepo,
    AppointmentTypeRepository appointmentTypeRepo,
  ) async {
    final profile = _ref.read(professionalProfileProvider).value;
    if (profile == null) {
      print("⚠️ No hay perfil profesional, se omite sincronización.");
      return;
    }

    print("🧠 Sincronizando datos profesional ${profile.id}");

    // Citas
    final appointments = await appointmentRepo.getAppointmentsForProfessional(
      profile.id,
    );
    print("📥 ${appointments.length} citas profesional descargadas.");

    // Tipos de cita
    final appointmentTypes = await appointmentTypeRepo
        .getAppointmentTypesForProfessional(profile.id);
    print("📦 ${appointmentTypes.length} tipos de cita descargados.");

    // Horarios
    final schedules = await scheduleRepo.getSchedulesForProfessional(
      profile.id,
    );
    print("🗓️ ${schedules.length} horarios descargados.");

    // Notas
    for (var appt in appointments) {
      final notes = await notesRepo.getNotesForAppointment(appt.id);
      print("📝 ${notes.length} notas para cita ${appt.id}");
    }

    final localAppointmentRepo = LocalAppointmentRepository();
    final localScheduleRepo = LocalScheduleRepository();
    final localTypeRepo = LocalAppointmentTypeRepository();

    await localAppointmentRepo.clearAppointments();
    await localScheduleRepo.clearSchedules();
    await localTypeRepo.clearAppointmentTypes();

    await localAppointmentRepo.insertAppointments(appointments);
    await localScheduleRepo.insertSchedules(schedules);
    await localTypeRepo.insertAppointmentTypes(
      appointmentTypes
          .map(
            (r) => {
              'id': r.id,
              'professionalId': profile.id,
              'name': r.data['name'],
            },
          )
          .toList(),
    );
  }
}

final offlineDataSyncProvider = Provider((ref) => OfflineDataSync(ref));
