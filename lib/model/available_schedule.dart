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
      professionalProfileId: record.data['professional'] as String,
      dayOfWeek: record.data['day_of_week'] as String,
      startTime: DateTime.parse('2000-01-01T${record.data['start_time']}'),
      endTime: DateTime.parse('2000-01-01T${record.data['end_time']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professional': professionalProfileId,
      'day_of_week': dayOfWeek,
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00.000',
      'end_time':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00.000',
    };
  }

  // toMap and fromMap methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'professionalProfileId': professionalProfileId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory AvailableSchedule.fromMap(Map<String, dynamic> map) {
    return AvailableSchedule(
      id: map['id'],
      professionalProfileId: map['professionalProfileId'],
      dayOfWeek: map['dayOfWeek'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
    );
  }

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
