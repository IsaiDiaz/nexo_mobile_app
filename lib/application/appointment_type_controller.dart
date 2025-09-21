// lib/application/appointment_type_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/appointment_type_repository.dart';

/// Estado del controlador de tipos de cita
class AppointmentTypeState {
  final List<pb.RecordModel> types;
  final bool isLoading;
  final String? errorMessage;

  AppointmentTypeState({
    required this.types,
    this.isLoading = false,
    this.errorMessage,
  });

  AppointmentTypeState copyWith({
    List<pb.RecordModel>? types,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppointmentTypeState(
      types: types ?? this.types,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controlador
class AppointmentTypeController extends StateNotifier<AppointmentTypeState> {
  final AppointmentTypeRepository _repository;
  final Ref _ref;

  AppointmentTypeController(this._repository, this._ref)
    : super(AppointmentTypeState(types: []));

  /// Cargar todos los tipos de cita de un profesional
  Future<void> loadAppointmentTypes(String professionalId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final types = await _repository.getAppointmentTypesForProfessional(
        professionalId,
      );
      state = state.copyWith(isLoading: false, types: types);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Crear un nuevo tipo de cita
  Future<String?> createAppointmentType({
    required String professionalId,
    required String name,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final record = await _repository.createAppointmentType(
        professionalId: professionalId,
        name: name,
      );

      // Agregarlo al estado actual
      final updated = [...state.types, record];
      state = state.copyWith(isLoading: false, types: updated);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  /// Actualizar un tipo de cita (solo el nombre en este caso)
  Future<String?> updateAppointmentType({
    required String appointmentTypeId,
    required String newName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final updatedRecord = await _repository.updateAppointmentType(
        appointmentTypeId: appointmentTypeId,
        name: newName,
      );

      final updatedList = state.types.map((t) {
        return t.id == updatedRecord.id ? updatedRecord : t;
      }).toList();

      state = state.copyWith(isLoading: false, types: updatedList);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }

  /// Eliminar un tipo de cita
  Future<String?> deleteAppointmentType(String appointmentTypeId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _repository.deleteAppointmentType(appointmentTypeId);

      final updatedList = state.types
          .where((t) => t.id != appointmentTypeId)
          .toList();

      state = state.copyWith(isLoading: false, types: updatedList);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return e.toString();
    }
  }
}

/// Provider principal
final appointmentTypeControllerProvider =
    StateNotifierProvider.autoDispose<
      AppointmentTypeController,
      AppointmentTypeState
    >((ref) {
      final repo = ref.watch(appointmentTypeRepositoryProvider);
      return AppointmentTypeController(repo, ref);
    });
