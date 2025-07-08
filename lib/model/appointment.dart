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
  final pb.RecordModel _originalRecord;
  final pb.RecordModel?
  professionalRecord; // ADDED: RecordModel for expanded professional data
  final pb.RecordModel?
  clientRecord; // OPTIONAL: RecordModel for expanded client data (useful for professional view)

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
    required pb.RecordModel originalRecord,
    this.professionalRecord,
    this.clientRecord,
  }) : _originalRecord = originalRecord;

  factory Appointment.fromRecord(pb.RecordModel record) {
    final startUtc = DateTime.parse(
      record.data['start'] as String,
    ).toLocal(); // Convertir a local para mostrar
    final endUtc = DateTime.parse(
      record.data['end'] as String,
    ).toLocal(); // Convertir a local para mostrar

    final professionalRecord = record.get<pb.RecordModel?>(
      'expand.professional',
    );
    final clientRecord = record.get<pb.RecordModel?>('expand.client');

    // Acceder a los datos expandidos si existen
    final professionalId =
        record.data['professional'] as String; // o 'professional_profile'
    final clientId = record.data['client'] as String;

    return Appointment(
      id: record.id,
      start: startUtc,
      end: endUtc,
      originalFee: (record.data['original_fee'] as num).toDouble(),
      discountFee: (record.data['discount_fee'] as num?)?.toDouble(),
      status: record.data['status'] as String,
      clientId: record.data['client'] as String,
      professionalProfileId:
          record.data['professional']
              as String, // Revisa el nombre del campo de relación
      type: record.data['type'] as String,
      originalRecord: record, // Guardamos el record original
      professionalRecord: professionalRecord,
      clientRecord: clientRecord,
    );
  }

  // Helper para mostrar la hora de inicio formateada
  String get formattedStartTime {
    final hour = start.hour;
    final minute = start.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Helper para mostrar la hora de fin formateada
  String get formattedEndTime {
    final hour = end.hour;
    final minute = end.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Helper para obtener el nombre del cliente
  String get clientName {
    // Intentamos obtener el RecordModel del cliente expandido
    // Asumimos que el campo de relación es 'client' y que la colección 'users' tiene un campo 'name'
    final clientExpandedRecord = _originalRecord.get<pb.RecordModel?>(
      'expand.client',
    );

    // Si el record expandido existe, obtenemos su campo 'name'
    return clientExpandedRecord?.get<String>('name') ?? 'Cliente Desconocido';
  }

  // Método toJson para enviar datos a PocketBase (para crear/actualizar)
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
    };
  }
}
