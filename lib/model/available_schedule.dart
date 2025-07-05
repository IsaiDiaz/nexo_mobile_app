import 'package:pocketbase/pocketbase.dart' as pb;

class AvailableSchedule {
  final String id;
  final String professionalProfileId;
  final String dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;

  AvailableSchedule({
    required this.id,
    required this.professionalProfileId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory AvailableSchedule.fromRecord(pb.RecordModel record) {
    return AvailableSchedule(
      id: record.id,
      professionalProfileId: record.data['professional_profile'] as String,
      dayOfWeek: record.data['day_of_week'] as String,
      startTime: DateTime.parse(
        '2000-01-01T${record.data['start_time']}Z',
      ).toLocal(),
      endTime: DateTime.parse(
        '2000-01-01T${record.data['end_time']}Z',
      ).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professional_profile': professionalProfileId,
      'day_of_week': dayOfWeek,
      // Formatear a HH:mm:ss.SSS para PocketBase 'time' field
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00.000',
      'end_time':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00.000',
      // 'created' y 'updated' son manejados por PocketBase al crear/actualizar
    };
  }

  // Helper para mostrar el tiempo en formato legible (ej. 09:00 AM)
  String get formattedStartTime {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedEndTime {
    final hour = endTime.hour;
    final minute = endTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
