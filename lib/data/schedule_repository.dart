import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexo/model/available_schedule.dart';
import 'package:nexo/data/auth_repository.dart';

class ScheduleRepository {
  final pb.PocketBase _pb;

  ScheduleRepository(this._pb);

  Future<List<AvailableSchedule>> getSchedulesForProfessional(
    String professionalProfileId,
  ) async {
    try {
      final records = await _pb
          .collection('available_schedule')
          .getFullList(
            filter: 'professional_profile = "$professionalProfileId"',
            sort: 'day_of_week, start_time',
          );
      return records
          .map((record) => AvailableSchedule.fromRecord(record))
          .toList();
    } on pb.ClientException catch (e) {
      print('Error en getSchedulesForProfessional: ${e.response}');
      throw Exception('Error al obtener horarios: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en getSchedulesForProfessional: $e');
      throw Exception('Ocurrió un error inesperado al obtener horarios: $e');
    }
  }

  Future<AvailableSchedule> createSchedule(AvailableSchedule schedule) async {
    try {
      final record = await _pb
          .collection('available_schedule')
          .create(body: schedule.toJson());
      return AvailableSchedule.fromRecord(record);
    } on pb.ClientException catch (e) {
      print('Error en createSchedule: ${e.response}');
      throw Exception('Error al crear horario: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en createSchedule: $e');
      throw Exception('Ocurrió un error inesperado al crear horario: $e');
    }
  }

  Future<AvailableSchedule> updateSchedule(AvailableSchedule schedule) async {
    try {
      final record = await _pb
          .collection('available_schedule')
          .update(schedule.id, body: schedule.toJson());
      return AvailableSchedule.fromRecord(record);
    } on pb.ClientException catch (e) {
      print('Error en updateSchedule: ${e.response}');
      throw Exception('Error al actualizar horario: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en updateSchedule: $e');
      throw Exception('Ocurrió un error inesperado al actualizar horario: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _pb.collection('available_schedule').delete(scheduleId);
    } on pb.ClientException catch (e) {
      print('Error en deleteSchedule: ${e.response}');
      throw Exception('Error al eliminar horario: ${e.response['message']}');
    } catch (e) {
      print('Error inesperado en deleteSchedule: $e');
      throw Exception('Ocurrió un error inesperado al eliminar horario: $e');
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ScheduleRepository(authRepository.pocketBase);
});
