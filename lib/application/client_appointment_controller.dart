// lib/application/client_appointment_controller.dart
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

class ClientAppointmentController extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repo;
  final Ref _ref;

  ClientAppointmentController(this._repo, this._ref)
    : super(const AppointmentState(appointments: [])) {
    // Escucha usuario y rol activo
    _ref.listen<pb.RecordModel?>(currentUserRecordProvider, (_, user) {
      final role = _ref.read(activeRoleProvider);
      if (role == UserRole.client && user != null) {
        loadClientAppointments();
      } else if (user == null) {
        state = state.copyWith(appointments: []);
      }
    });

    _ref.listen<UserRole?>(activeRoleProvider, (_, role) {
      if (role == UserRole.client) {
        final user = _ref.read(currentUserRecordProvider);
        if (user != null) {
          loadClientAppointments();
        }
      } else {
        state = state.copyWith(appointments: []);
      }
    });

    // Carga inicial si ya hay usuario+rol
    final role = _ref.read(activeRoleProvider);
    final user = _ref.read(currentUserRecordProvider);
    if (role == UserRole.client && user != null) {
      loadClientAppointments();
    }
  }

  Future<void> loadClientAppointments() async {
    if (state.isLoading) return;

    final user = _ref.read(currentUserRecordProvider);
    if (user == null) {
      state = state.copyWith(
        appointments: [],
        isLoading: false,
        errorMessage: 'No se encontró usuario.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAppointmentsForClient(user.id);
      state = state.copyWith(appointments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
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
      await loadClientAppointments();
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }
}

final clientAppointmentControllerProvider =
    StateNotifierProvider.autoDispose<
      ClientAppointmentController,
      AppointmentState
    >((ref) {
      final repo = ref.watch(appointmentRepositoryProvider);
      return ClientAppointmentController(repo, ref);
    });

// Derivados SOLO para cliente
final clientUpcomingAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final s = ref.watch(clientAppointmentControllerProvider);
      final user = ref.read(currentUserRecordProvider);
      if (user == null) return [];
      final now = DateTime.now();
      return s.appointments
          .where(
            (a) =>
                a.clientId == user.id &&
                a.end.isAfter(now) &&
                (a.status == 'Pendiente' || a.status == 'Confirmada'),
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
    });

final clientCompletedAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final s = ref.watch(clientAppointmentControllerProvider);
      final user = ref.read(currentUserRecordProvider);
      if (user == null) return [];
      final now = DateTime.now();
      return s.appointments
          .where(
            (a) =>
                a.clientId == user.id &&
                (a.status == 'Confirmada' || a.status == 'Completada') &&
                a.end.isBefore(now),
          )
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));
    });
