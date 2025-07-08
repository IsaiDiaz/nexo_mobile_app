import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/model/appointment.dart';

class AppointmentRepository {
  final pb.PocketBase _pb;

  AppointmentRepository(this._pb);

  // Método para obtener citas para un profesional específico
  Future<List<Appointment>> getAppointmentsForProfessional(
    String professionalProfileId, {
    String statusFilter = '', // Opcional: para filtrar por estado
    String orderBy = '-start', // Ordenar por fecha de inicio descendente
  }) async {
    try {
      // Necesitamos expandir los registros de 'client' para obtener el nombre del cliente
      final records = await _pb
          .collection('appointment')
          .getFullList(
            filter:
                'professional = "$professionalProfileId"${statusFilter.isNotEmpty ? ' && status = "$statusFilter"' : ''}',
            sort: orderBy,
            expand: 'client', // Expandir el registro del cliente
          );

      return records.map((record) => Appointment.fromRecord(record)).toList();
    } on pb.ClientException catch (e) {
      print(
        'PocketBase ClientException in getAppointmentsForProfessional: ${e.response}',
      );
      throw Exception('Error al obtener citas: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en getAppointmentsForProfessional: $e');
      throw Exception('Error inesperado al obtener citas: $e');
    }
  }

  // Método para actualizar el estado de una cita (ej. confirmar/cancelar)
  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    try {
      final updatedRecord = await _pb
          .collection('appointment')
          .update(appointmentId, body: {'status': newStatus});
      // Opcional: re-expandir si necesitas los datos relacionados actualizados
      final reFetchedRecord = await _pb
          .collection('appointment')
          .getOne(appointmentId, expand: 'client');
      return Appointment.fromRecord(reFetchedRecord);
    } on pb.ClientException catch (e) {
      print(
        'PocketBase ClientException in updateAppointmentStatus: ${e.response}',
      );
      throw Exception('Error al actualizar cita: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en updateAppointmentStatus: $e');
      throw Exception('Error inesperado al actualizar cita: $e');
    }
  }

  Future<Appointment> createAppointment({
    required DateTime start,
    required DateTime end,
    required String professionalProfileId,
    required String clientId,
    required String service,
    required double originalFee,
    String status = 'Pendiente',
  }) async {
    try {
      final newAppointmentData = {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'professional':
            professionalProfileId, // Campo de relación al perfil profesional
        'client': clientId, // Campo de relación al usuario cliente
        'type': service, // CORRECCIÓN: Mapear a 'type' según tu DB
        'original_fee': originalFee,
        'status': status,
      };

      final record = await _pb
          .collection('appointment')
          .create(body: newAppointmentData, expand: 'client');
      return Appointment.fromRecord(record);
    } on pb.ClientException catch (e) {
      print('PocketBase ClientException in createAppointment: ${e.response}');
      throw Exception('Error al crear cita: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en createAppointment: $e');
      throw Exception('Error inesperado al crear cita: $e');
    }
  }

  Future<List<Appointment>> getAppointmentsForClient(String clientId) async {
    try {
      final records = await _pb
          .collection('appointment')
          .getFullList(
            filter: 'client = "$clientId"',
            sort: '-start', // Sort by start date, descending
            expand:
                'professional.user', // Expand professional and its user data
          );
      return records.map((record) => Appointment.fromRecord(record)).toList();
    } on pb.ClientException catch (e) {
      print('Error al obtener citas del cliente: ${e.response}');
      throw Exception(
        'Error al obtener citas del cliente: ${e.response['message']}',
      );
    } catch (e) {
      print('Ocurrió un error inesperado al obtener citas del cliente: $e');
      throw Exception(
        'Ocurrió un error inesperado al obtener citas del cliente: $e',
      );
    }
  }

  //deleteAppointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _pb.collection('appointment').delete(appointmentId);
    } on pb.ClientException catch (e) {
      print('Error al eliminar cita: ${e.response}');
      throw Exception('Error al eliminar cita: ${e.response['message']}');
    } catch (e) {
      print('Ocurrió un error inesperado al eliminar cita: $e');
      throw Exception('Ocurrió un error inesperado al eliminar cita: $e');
    }
  }

  // Puedes añadir métodos para crear, eliminar citas si el profesional lo hace
  // o si decides que el profesional pueda crear citas directamente.
  // Por ahora, nos centraremos en la visualización y actualización de estado.
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final pocketBase = ref.watch(authRepositoryProvider).pocketBase;
  return AppointmentRepository(pocketBase);
});
