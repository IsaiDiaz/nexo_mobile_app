import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/model/appointment.dart';

class AppointmentRepository {
  final pb.PocketBase _pb;

  AppointmentRepository(this._pb);

  Future<List<Appointment>> getAppointmentsForProfessional(
    String professionalProfileId, {
    String statusFilter = '',
    String orderBy = '-start',
  }) async {
    try {
      final records = await _pb
          .collection('appointment')
          .getFullList(
            filter:
                'professional = "$professionalProfileId"${statusFilter.isNotEmpty ? ' && status = "$statusFilter"' : ''}',
            sort: orderBy,
            expand: 'client',
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

  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    try {
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
    String comments = '',
    required double originalFee,
    String status = 'Pendiente',
  }) async {
    try {
      final newAppointmentData = {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'professional': professionalProfileId,
        'client': clientId,
        'type': service,
        'comments': comments,
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
            sort: '-start',
            expand: 'professional.user',
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
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final pocketBase = ref.watch(authRepositoryProvider).pocketBase;
  return AppointmentRepository(pocketBase);
});
