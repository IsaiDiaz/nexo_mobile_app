// lib/data/appointment_type_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';

class AppointmentTypeRepository {
  final pb.PocketBase _pb;

  AppointmentTypeRepository(this._pb);

  /// Lista los tipos de cita del perfil profesional dado
  Future<List<pb.RecordModel>> getAppointmentTypesForProfessional(
    String professionalProfileId, {
    String orderBy = 'name',
  }) async {
    try {
      final records = await _pb
          .collection('appointment_type')
          .getFullList(
            filter: 'professional = "$professionalProfileId"',
            sort: orderBy,
          );
      return records;
    } on pb.ClientException catch (e) {
      // Logs útiles
      // print('PB ClientException in getAppointmentTypesForProfessional: ${e.response}');
      throw Exception(
        'Error al obtener tipos de cita: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception('Error inesperado al obtener tipos de cita: $e');
    }
  }

  /// Crea un nuevo tipo de cita para el profesional
  Future<pb.RecordModel> createAppointmentType({
    required String professionalId,
    required String name,
  }) async {
    try {
      final data = {'name': name, 'professional': professionalId};
      final record = await _pb
          .collection('appointment_type')
          .create(body: data);
      return record;
    } on pb.ClientException catch (e) {
      // print('PB ClientException in createAppointmentType: ${e.response}');
      throw Exception('Error al crear tipo de cita: ${e.response['message']}');
    } catch (e) {
      throw Exception('Error inesperado al crear tipo de cita: $e');
    }
  }

  /// Actualiza el nombre de un tipo de cita (opcional, por si luego quieres editar)
  Future<pb.RecordModel> updateAppointmentType({
    required String appointmentTypeId,
    required String name,
  }) async {
    try {
      final record = await _pb
          .collection('appointment_type')
          .update(appointmentTypeId, body: {'name': name});
      return record;
    } on pb.ClientException catch (e) {
      // print('PB ClientException in updateAppointmentType: ${e.response}');
      throw Exception(
        'Error al actualizar tipo de cita: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception('Error inesperado al actualizar tipo de cita: $e');
    }
  }

  /// Elimina un tipo de cita
  Future<void> deleteAppointmentType(String appointmentTypeId) async {
    try {
      await _pb.collection('appointment_type').delete(appointmentTypeId);
    } on pb.ClientException catch (e) {
      // print('PB ClientException in deleteAppointmentType: ${e.response}');
      throw Exception(
        'Error al eliminar tipo de cita: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception('Error inesperado al eliminar tipo de cita: $e');
    }
  }
}

/// Provider del repositorio
final appointmentTypeRepositoryProvider = Provider<AppointmentTypeRepository>((
  ref,
) {
  final pb = ref.watch(authRepositoryProvider).pocketBase;
  return AppointmentTypeRepository(pb);
});

/// FutureProvider.family para traer los tipos por profesional
final appointmentTypesProvider =
    FutureProvider.family<List<pb.RecordModel>, String>((ref, professionalId) {
      final repo = ref.watch(appointmentTypeRepositoryProvider);
      return repo.getAppointmentTypesForProfessional(professionalId);
    });
