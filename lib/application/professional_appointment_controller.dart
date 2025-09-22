// lib/application/professional_appointment_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;

import 'package:nexo/data/appointment_repository.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/model/registration_data.dart';

class AppointmentState {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? errorMessage;

  const AppointmentState({
    required this.appointments,
    this.isLoading = false,
    this.errorMessage,
  });

  AppointmentState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ProfessionalAppointmentController
    extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repo;
  final Ref _ref;

  ProfessionalAppointmentController(this._repo, this._ref)
    : super(const AppointmentState(appointments: [])) {
    // Escucha el perfil profesional y rol activo: solo carga cuando hay perfil y rol=professional
    _ref.listen<AsyncValue<pb.RecordModel?>>(professionalProfileProvider, (
      _,
      next,
    ) {
      next.whenOrNull(
        data: (profile) {
          final activeRole = _ref.read(activeRoleProvider);
          if (activeRole == UserRole.professional && profile != null) {
            loadProfessionalAppointments();
          } else if (profile == null) {
            state = state.copyWith(appointments: []);
          }
        },
        error: (err, _) => state = state.copyWith(errorMessage: 'Error: $err'),
      );
    });

    _ref.listen<UserRole?>(activeRoleProvider, (_, role) {
      if (role == UserRole.professional) {
        final profile = _ref.read(professionalProfileProvider).value;
        if (profile != null) {
          loadProfessionalAppointments();
        }
      } else {
        // Si deja de ser profesional, limpia el estado
        state = state.copyWith(appointments: []);
      }
    });

    // Carga inicial si ya hay perfil+rol
    final role = _ref.read(activeRoleProvider);
    final profile = _ref.read(professionalProfileProvider).value;
    if (role == UserRole.professional && profile != null) {
      loadProfessionalAppointments();
    }
  }

  Future<void> loadProfessionalAppointments() async {
    // Evita cargas en paralelo
    if (state.isLoading) return;

    final profile = _ref.read(professionalProfileProvider).value;
    if (profile == null) {
      state = state.copyWith(
        appointments: [],
        isLoading: false,
        errorMessage: 'No se encontró perfil profesional.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAppointmentsForProfessional(profile.id);
      state = state.copyWith(appointments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<String?> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final updated = await _repo.updateAppointmentStatus(
        appointmentId,
        status,
      );
      state = state.copyWith(
        appointments: state.appointments
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
        isLoading: false,
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  Future<String?> createAppointment({
    required DateTime start,
    required DateTime end,
    required String professionalProfileId,
    required String clientId,
    required String service,
    String comments = '',
    required double originalFee,
    String status = 'Pendiente',
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _repo.createAppointment(
        start: start,
        end: end,
        professionalProfileId: professionalProfileId,
        clientId: clientId,
        service: service,
        comments: comments,
        originalFee: originalFee,
        status: status,
      );
      // Re-cargar lista para evitar estados inconsistentes
      await loadProfessionalAppointments();
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  Future<String?> deleteAppointment(String appointmentId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _repo.deleteAppointment(appointmentId);
      state = state.copyWith(
        appointments: state.appointments
            .where((a) => a.id != appointmentId)
            .toList(),
        isLoading: false,
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }
}

final professionalAppointmentControllerProvider =
    StateNotifierProvider.autoDispose<
      ProfessionalAppointmentController,
      AppointmentState
    >((ref) {
      final repo = ref.watch(appointmentRepositoryProvider);
      return ProfessionalAppointmentController(repo, ref);
    });

// Derivados SOLO para profesional
final professionalUpcomingAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final s = ref.watch(professionalAppointmentControllerProvider);
      final now = DateTime.now();
      final list = s.appointments.where((a) => a.end.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      return list;
    });

final professionalPendingAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final s = ref.watch(professionalAppointmentControllerProvider);
      return s.appointments.where((a) => a.status == 'Pendiente').toList();
    });

final professionalConfirmedAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final s = ref.watch(professionalAppointmentControllerProvider);
      return s.appointments
          .where(
            (a) => a.status == 'Confirmada' && a.end.isAfter(DateTime.now()),
          )
          .toList();
    });
