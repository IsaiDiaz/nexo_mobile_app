import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/schedule_repository.dart';
import 'package:nexo/model/available_schedule.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:pocketbase/pocketbase.dart' as pb;

class ScheduleState {
  final List<AvailableSchedule> schedules;
  final bool isLoading;
  final String? errorMessage;

  ScheduleState({
    required this.schedules,
    this.isLoading = false,
    this.errorMessage,
  });

  ScheduleState copyWith({
    List<AvailableSchedule>? schedules,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ScheduleController extends StateNotifier<ScheduleState> {
  final ScheduleRepository _scheduleRepository;
  final Ref _ref;

  ScheduleController(this._scheduleRepository, this._ref)
    : super(ScheduleState(schedules: [])) {
    _ref.listen<AsyncValue<pb.RecordModel?>>(professionalProfileProvider, (
      _,
      next,
    ) {
      next.whenOrNull(
        data: (profile) {
          if (profile != null) {
            loadSchedules();
          } else {
            if (state.schedules.isNotEmpty) {
              state = state.copyWith(schedules: []);
            }
          }
        },
        error: (err, stack) {
          state = state.copyWith(
            errorMessage: 'Error al cargar perfil profesional: $err',
          );
        },
      );
    });

    final initialProfileAsyncValue = _ref.read(professionalProfileProvider);
    initialProfileAsyncValue.whenOrNull(
      data: (profile) {
        if (profile != null) {
          loadSchedules();
        }
      },
    );
  }

  Future<void> loadSchedules() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final professionalProfile = _ref.read(professionalProfileProvider).value;
      if (professionalProfile == null) {
        state = state.copyWith(
          isLoading: false,
          schedules: [],
          errorMessage:
              'No se encontró el perfil profesional para cargar horarios.',
        );
        return;
      }
      final schedules = await _scheduleRepository.getSchedulesForProfessional(
        professionalProfile.id,
      );
      state = state.copyWith(isLoading: false, schedules: schedules);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Agregar un nuevo horario
  Future<String?> addSchedule({
    required String dayOfWeek,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final professionalProfile = _ref.read(professionalProfileProvider).value;
      if (professionalProfile == null) {
        state = state.copyWith(isLoading: false);
        return 'No se encontró el perfil profesional.';
      }

      final existingSchedulesForDay = state.schedules
          .where((s) => s.dayOfWeek == dayOfWeek)
          .toList();

      for (var existing in existingSchedulesForDay) {
        if ((startTime.isBefore(existing.endTime) &&
            endTime.isAfter(existing.startTime))) {
          state = state.copyWith(isLoading: false);
          return 'El horario se superpone con un bloque existente.';
        }
      }

      final newSchedule = AvailableSchedule(
        id: '',
        professionalProfileId: professionalProfile.id,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
      final createdSchedule = await _scheduleRepository.createSchedule(
        newSchedule,
      );
      state = state.copyWith(
        isLoading: false,
        schedules: [...state.schedules, createdSchedule]
          ..sort((a, b) {
            final dayOrder = [
              'monday',
              'tuesday',
              'wednesday',
              'thursday',
              'friday',
              'saturday',
              'sunday',
            ];
            final compareDay = dayOrder
                .indexOf(a.dayOfWeek)
                .compareTo(dayOrder.indexOf(b.dayOfWeek));
            if (compareDay != 0) return compareDay;
            return a.startTime.compareTo(b.startTime);
          }),
      );
      return null; // Éxito
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  Future<String?> updateSchedule(AvailableSchedule schedule) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedSchedule = await _scheduleRepository.updateSchedule(
        schedule,
      );
      state = state.copyWith(
        isLoading: false,
        schedules:
            state.schedules.map((s) {
              return s.id == updatedSchedule.id ? updatedSchedule : s;
            }).toList()..sort((a, b) {
              final dayOrder = [
                'monday',
                'tuesday',
                'wednesday',
                'thursday',
                'friday',
                'saturday',
                'sunday',
              ];
              final compareDay = dayOrder
                  .indexOf(a.dayOfWeek)
                  .compareTo(dayOrder.indexOf(b.dayOfWeek));
              if (compareDay != 0) return compareDay;
              return a.startTime.compareTo(b.startTime);
            }),
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  Future<String?> deleteSchedule(String scheduleId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _scheduleRepository.deleteSchedule(scheduleId);
      state = state.copyWith(
        isLoading: false,
        schedules: state.schedules.where((s) => s.id != scheduleId).toList(),
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }
}

final scheduleControllerProvider =
    StateNotifierProvider.autoDispose<ScheduleController, ScheduleState>((ref) {
      final scheduleRepository = ref.watch(scheduleRepositoryProvider);
      return ScheduleController(scheduleRepository, ref);
    });

final groupedSchedulesProvider =
    Provider.autoDispose<Map<String, List<AvailableSchedule>>>((ref) {
      final scheduleState = ref.watch(scheduleControllerProvider);
      if (scheduleState.isLoading)
        return {}; // O un mapa vacío si está cargando

      final Map<String, List<AvailableSchedule>> grouped = {};
      final dayNames = {
        'monday': 'Lunes',
        'tuesday': 'Martes',
        'wednesday': 'Miércoles',
        'thursday': 'Jueves',
        'friday': 'Viernes',
        'saturday': 'Sábado',
        'sunday': 'Domingo',
      };

      final orderedDays = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];

      for (var dayKey in orderedDays) {
        grouped[dayNames[dayKey]!] =
            scheduleState.schedules.where((s) => s.dayOfWeek == dayKey).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      return grouped;
    });
