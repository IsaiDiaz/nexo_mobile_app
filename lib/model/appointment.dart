import 'package:pocketbase/pocketbase.dart' as pb;

class Appointment {
  final String id;
  final DateTime start;
  final DateTime end;
  final double originalFee;
  final double? discountFee;
  final String status;
  final String clientId;
  final String professionalProfileId;
  final String? type;
  final String? comments;
  final pb.RecordModel _originalRecord;
  final pb.RecordModel? professionalRecord;
  final pb.RecordModel? clientRecord;

  Appointment({
    required this.id,
    required this.start,
    required this.end,
    required this.originalFee,
    this.discountFee,
    required this.status,
    required this.clientId,
    required this.professionalProfileId,
    required this.type,
    this.comments = '',
    required pb.RecordModel originalRecord,
    this.professionalRecord,
    this.clientRecord,
  }) : _originalRecord = originalRecord;

  factory Appointment.fromRecord(pb.RecordModel record) {
    final startUtc = DateTime.parse(record.data['start'] as String).toUtc();
    final endUtc = DateTime.parse(record.data['end'] as String).toUtc();

    final professionalRecord = record.get<pb.RecordModel?>(
      'expand.professional',
    );
    final clientRecord = record.get<pb.RecordModel?>('expand.client');

    return Appointment(
      id: record.id,
      start: startUtc,
      end: endUtc,
      originalFee: (record.data['original_fee'] as num).toDouble(),
      discountFee: (record.data['discount_fee'] as num?)?.toDouble(),
      status: record.data['status'] as String,
      clientId: record.data['client'] as String,
      professionalProfileId: record.data['professional'] as String,
      type: record.data['type'] as String,
      comments: record.data['comments']?.toString(),
      originalRecord: record,
      professionalRecord: professionalRecord,
      clientRecord: clientRecord,
    );
  }

  String get formattedStartTime {
    final hour = start.hour;
    final minute = start.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedEndTime {
    final hour = end.hour;
    final minute = end.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get clientName {
    final clientExpandedRecord = _originalRecord.get<pb.RecordModel?>(
      'expand.client',
    );
    return clientExpandedRecord?.get<String>('name') ?? 'Cliente Desconocido';
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'original_fee': originalFee,
      'discount_fee': discountFee,
      'status': status,
      'client': clientId,
      'professional': professionalProfileId,
      'type': type,
      'comments': comments,
    };
  }

  String toString() {
    return 'Appointment(id: $id, start: $start, end: $end, originalFee: $originalFee, discountFee: $discountFee, status: $status, clientId: $clientId, professionalProfileId: $professionalProfileId, type: $type, comments: $comments)';
  }
}
