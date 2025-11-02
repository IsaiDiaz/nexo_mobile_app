import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/appointment_repository.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/appointment.dart';
import 'package:nexo/data/local/local_appointment_repository.dart';
import 'package:nexo/data/auth_offline_repository.dart';

class AppointmentState {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? errorMessage;

  AppointmentState({
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

class AppointmentController extends StateNotifier<AppointmentState> {
  final AppointmentRepository _appointmentRepository;
  final Ref _ref;

  AppointmentController(this._appointmentRepository, this._ref)
    : super(AppointmentState(appointments: [])) {
    _ref.listen<AsyncValue<pb.RecordModel?>>(professionalProfileProvider, (
      _,
      next,
    ) {
      next.whenOrNull(
        data: (profile) {
          if (profile != null) {
            loadProfessionalAppointments();
          } else {
            if (state.appointments.isNotEmpty) {
              state = state.copyWith(appointments: []);
            }
          }
        },
        error: (err, stack) {
          state = state.copyWith(
            errorMessage: 'Error al cargar perfil profesional para citas: $err',
          );
        },
      );
    });

    _ref.listen<pb.RecordModel?>(currentUserRecordProvider, (
      _,
      nextClientUser,
    ) {
      if (nextClientUser != null) {
        loadClientAppointments();
      } else {
        if (state.appointments.isNotEmpty) {
          state = state.copyWith(appointments: []);
        }
      }
    });

    final initialProfileAsyncValue = _ref.read(professionalProfileProvider);
    initialProfileAsyncValue.whenOrNull(
      data: (profile) {
        if (profile != null) {
          loadProfessionalAppointments();
        }
      },
    );

    final initialClientUser = _ref.read(currentUserRecordProvider);
    if (initialClientUser != null) {
      loadClientAppointments();
    }
  }

  Future<void> loadProfessionalAppointments() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final isOffline = _ref.read(offlineModeProvider);

      if (isOffline) {
        // 🔸 Cargar desde SQLite
        final localRepo = LocalAppointmentRepository();
        final cachedAppointments = await localRepo.getAppointments();
        state = state.copyWith(
          isLoading: false,
          appointments: cachedAppointments,
        );
        return;
      }

      final professionalProfile = _ref.read(professionalProfileProvider).value;

      if (professionalProfile == null) {
        state = state.copyWith(
          isLoading: false,
          appointments: [],
          errorMessage:
              'No se encontró el perfil profesional para cargar citas.',
        );
        return;
      }

      final appointments = await _appointmentRepository
          .getAppointmentsForProfessional(professionalProfile.id);
      state = state.copyWith(isLoading: false, appointments: appointments);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadClientAppointments() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final clientUser = _ref.read(currentUserRecordProvider);

      if (clientUser == null) {
        state = state.copyWith(
          isLoading: false,
          appointments: [],
          errorMessage: 'No se encontró el usuario cliente para cargar citas.',
        );
        return;
      }

      final appointments = await _appointmentRepository
          .getAppointmentsForClient(clientUser.id);
      state = state.copyWith(isLoading: false, appointments: appointments);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    final link = _ref.keepAlive();
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final updatedAppointment = await _appointmentRepository
          .updateAppointmentStatus(appointmentId, newStatus);
      state = state.copyWith(
        isLoading: false,
        appointments: state.appointments
            .map((a) => a.id == updatedAppointment.id ? updatedAppointment : a)
            .toList(),
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    } finally {
      link.close();
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
    final link = _ref.keepAlive();
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final _ = await _appointmentRepository.createAppointment(
        start: start,
        end: end,
        professionalProfileId: professionalProfileId,
        clientId: clientId,
        service: service,
        comments: comments,
        originalFee: originalFee,
        status: status,
      );
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    } finally {
      link.close();
    }
  }

  Future<String?> deleteAppointment(String appointmentId) async {
    final link = _ref.keepAlive();
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _appointmentRepository.deleteAppointment(appointmentId);
      state = state.copyWith(
        isLoading: false,
        appointments: state.appointments
            .where((a) => a.id != appointmentId)
            .toList(),
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    } finally {
      link.close();
    }
  }
}

final appointmentControllerProvider =
    StateNotifierProvider.autoDispose<AppointmentController, AppointmentState>((
      ref,
    ) {
      final appointmentRepository = ref.watch(appointmentRepositoryProvider);
      return AppointmentController(appointmentRepository, ref);
    });

final pendingAppointmentsProvider = Provider.autoDispose<List<Appointment>>((
  ref,
) {
  final appointmentsState = ref.watch(appointmentControllerProvider);
  return appointmentsState.appointments
      .where((a) => a.status == 'Pendiente')
      .toList();
});

final confirmedAppointmentsProvider = Provider.autoDispose<List<Appointment>>((
  ref,
) {
  final appointmentsState = ref.watch(appointmentControllerProvider);
  return appointmentsState.appointments
      .where((a) => a.status == 'Confirmada')
      .toList();
});

final upcomingAppointmentsProvider = Provider.autoDispose<List<Appointment>>((
  ref,
) {
  final appointmentsState = ref.watch(appointmentControllerProvider);
  final now = DateTime.now();
  return appointmentsState.appointments
      .where((a) => a.end.isAfter(now))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
});

final clientUpcomingAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final appointmentsState = ref.watch(appointmentControllerProvider);

      final currentUser = ref.read(currentUserRecordProvider);
      if (currentUser == null) return [];
      final now = DateTime.now();
      return appointmentsState.appointments
          .where(
            (a) =>
                a.clientId == currentUser.id &&
                a.end.isAfter(now) &&
                (a.status == 'Pendiente' || a.status == 'Confirmada'),
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
    });

final clientPendingAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final appointmentsState = ref.watch(appointmentControllerProvider);
      final currentUser = ref.read(currentUserRecordProvider);
      if (currentUser == null) return [];
      return appointmentsState.appointments
          .where((a) => a.clientId == currentUser.id && a.status == 'Pendiente')
          .toList();
    });

final clientConfirmedAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final appointmentsState = ref.watch(appointmentControllerProvider);

      final currentUser = ref.read(currentUserRecordProvider);
      if (currentUser == null) return [];
      return appointmentsState.appointments
          .where(
            (a) =>
                a.clientId == currentUser.id &&
                a.status == 'Confirmada' &&
                a.end.isAfter(DateTime.now()),
          )
          .toList();
    });

final clientCompletedAppointmentsProvider =
    Provider.autoDispose<List<Appointment>>((ref) {
      final appointmentsState = ref.watch(appointmentControllerProvider);

      final currentUser = ref.read(currentUserRecordProvider);
      if (currentUser == null) return [];
      final now = DateTime.now();
      return appointmentsState.appointments
          .where(
            (a) =>
                a.clientId == currentUser.id &&
                (a.status == 'Confirmada' || a.status == 'Completada') &&
                a.end.isBefore(now),
          )
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));
    });
