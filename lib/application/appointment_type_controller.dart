import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/appointment_type_repository.dart';
import 'package:nexo/data/auth_offline_repository.dart';
import 'package:nexo/data/local/local_appointment_type_repository.dart';

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
      final isOffline = _ref.read(offlineModeProvider);
      if (isOffline) {
        // 🔸 Cargar desde SQLite y convertir a RecordModel con fromJson
        final localRepo = LocalAppointmentTypeRepository();
        final localRows = await localRepo.getAppointmentTypes();

        final nowIso = DateTime.now().toUtc().toIso8601String();
        final records = localRows.map((m) {
          return pb.RecordModel.fromJson({
            'id': m['id'],
            'collectionId': 'local_appointment_types',
            'collectionName': 'appointment_types',
            'created': nowIso,
            'updated': nowIso,
            'data': {'professionalId': m['professionalId'], 'name': m['name']},
            'expand': {},
          });
        }).toList();

        state = state.copyWith(isLoading: false, types: records);
        return;
      }

      // 🔸 Online normal
      final types = await _repository.getAppointmentTypesForProfessional(
        professionalId,
      );

      // Guardar en SQLite
      final localRepo = LocalAppointmentTypeRepository();
      await localRepo.clearAppointmentTypes();
      final mapped = types.map((t) {
        return {
          'id': t.id,
          'professionalId': t.getStringValue('professionalId'),
          'name': t.getStringValue('name'),
        };
      }).toList();
      await localRepo.insertAppointmentTypes(mapped);

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

      // Persistir también en SQLite
      final localRepo = LocalAppointmentTypeRepository();
      await localRepo.insertAppointmentTypes([
        {
          'id': record.id,
          'professionalId': record.getStringValue('professionalId'),
          'name': record.getStringValue('name'),
        },
      ]);

      state = state.copyWith(isLoading: false, types: [...state.types, record]);
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

      // Actualizar SQLite con el snapshot completo
      final localRepo = LocalAppointmentTypeRepository();
      final mapped = updatedList
          .map(
            (t) => {
              'id': t.id,
              'professionalId': t.getStringValue('professionalId'),
              'name': t.getStringValue('name'),
            },
          )
          .toList();
      await localRepo.clearAppointmentTypes();
      await localRepo.insertAppointmentTypes(mapped);

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

      // Reflejar en SQLite
      final localRepo = LocalAppointmentTypeRepository();
      final mapped = updatedList
          .map(
            (t) => {
              'id': t.id,
              'professionalId': t.getStringValue('professionalId'),
              'name': t.getStringValue('name'),
            },
          )
          .toList();
      await localRepo.clearAppointmentTypes();
      await localRepo.insertAppointmentTypes(mapped);

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
