// lib/presentation/widgets/professional_details_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/model/available_schedule.dart';
import 'package:nexo/application/appointment_controller.dart';
import 'package:nexo/application/auth_controller.dart'; // Para obtener el ID del cliente
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/data/schedule_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

final _professionalSchedulesProvider =
    FutureProvider.family<List<AvailableSchedule>, String>((
      ref,
      professionalProfileId,
    ) async {
      return ref
          .read(scheduleRepositoryProvider)
          .getSchedulesForProfessional(professionalProfileId);
    });

class ProfessionalDetailsSheet extends ConsumerStatefulWidget {
  final pb.RecordModel professionalProfile;

  const ProfessionalDetailsSheet({
    super.key,
    required this.professionalProfile,
  });

  @override
  ConsumerState<ProfessionalDetailsSheet> createState() =>
      _ProfessionalDetailsSheetState();
}

class _ProfessionalDetailsSheetState
    extends ConsumerState<ProfessionalDetailsSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String?
  _selectedServiceType; // Renombrado a _selectedServiceType para reflejar 'type' en DB

  // CORRECCIÓN: Los tipos de servicio (select en 'appointment.type')
  // Estos deberían ser los valores válidos para el campo 'type' de tu colección 'appointment'.
  // Si los servicios dependen de la 'category' del profesional, tendrías que cargarlos dinámicamente.
  // Por ahora, usamos ejemplos que podrían ser válidos para 'type'.
  final List<String> _appointmentTypes = [
    'Consulta',
    'Sesión',
    'Asesoría',
    'Clase',
  ]; // Valores de ejemplo para 'type'

  String? _getAvatarUrl(pb.RecordModel professionalProfile, WidgetRef ref) {
    final userRecord = professionalProfile.get<pb.RecordModel?>('expand.user');
    if (userRecord != null) {
      final avatar = userRecord.get<String?>('avatar');
      if (avatar != null && avatar.isNotEmpty) {
        // Obtener la instancia de PocketBase del authRepositoryProvider
        final pocketBase = ref.read(authRepositoryProvider).pocketBase;
        // Usar pocketBase.files.getURL para construir la URL
        return pocketBase.files.getURL(userRecord, avatar).toString();
      }
    }
    return null;
  }

  LatLng? _getCoordinates(pb.RecordModel professionalProfile) {
    final coordinateData = professionalProfile.data['coordinate'];
    if (coordinateData is Map<String, dynamic> &&
        coordinateData.containsKey('lat') &&
        coordinateData.containsKey('lon')) {
      final lat = coordinateData['lat'];
      final lon = coordinateData['lon'];
      // PocketBase almacena lat y lon como doubles.
      if (lat is double && lon is double) {
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryTextColor = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final cardColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;
    final accentButtonColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;

    final userRecord = widget.professionalProfile.get<pb.RecordModel?>(
      'expand.user',
    );

    final professionalName =
        userRecord?.get<String>('name') ?? 'Nombre Desconocido'; //
    final professionalDescription =
        widget.professionalProfile.get<String?>('description') ??
        'No hay descripción.'; // Campo 'description'
    final professionalLocation =
        widget.professionalProfile.get<String?>('address') ??
        'Ubicación no especificada.';

    final LatLng? professionalCoordinates = _getCoordinates(
      widget.professionalProfile,
    );

    print('DEBUG: professionalCoordinates: $professionalCoordinates');

    final schedulesAsyncValue = ref.watch(
      _professionalSchedulesProvider(widget.professionalProfile.id),
    );

    final daysOfWeekOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final Map<String, String> dayDisplayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                professionalName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                professionalDescription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      // Usar Flexible para que el texto no se desborde
                      child: Text(
                        professionalLocation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines:
                            2, // Limitar a dos líneas para evitar desbordamiento
                        overflow: TextOverflow
                            .ellipsis, // Añadir puntos suspensivos si excede
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (professionalCoordinates != null) ...[
                Text(
                  'Ubicación en el mapa:',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200, // Altura fija para el mapa
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: secondaryTextColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    // Para que el mapa se ajuste al borde redondeado
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: professionalCoordinates,
                        initialZoom: 15.0, // Un buen zoom para ver el punto
                        // Evita que el mapa se mueva para que solo sea una visualización
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.nexo', // Reemplaza con el nombre de tu paquete
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: professionalCoordinates,
                              width: 80.0,
                              height: 80.0,
                              child: Icon(
                                Icons.location_pin,
                                color: theme.colorScheme.primary,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Horarios de Disponibilidad:',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              schedulesAsyncValue.when(
                data: (availableSchedules) {
                  if (availableSchedules.isEmpty) {
                    return Text(
                      'Este profesional no ha configurado sus horarios de disponibilidad.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    );
                  }
                  final Map<String, List<AvailableSchedule>> groupedSchedules =
                      {};
                  for (var schedule in availableSchedules) {
                    groupedSchedules
                        .putIfAbsent(schedule.dayOfWeek, () => [])
                        .add(schedule);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: daysOfWeekOrder.map((day) {
                      final schedulesForDay = groupedSchedules[day];
                      if (schedulesForDay == null || schedulesForDay.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayDisplayNames[day]!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...schedulesForDay
                                .map(
                                  (s) => Text(
                                    '${s.formattedStartTime} - ${s.formattedEndTime}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                error: (err, stack) => Text(
                  'Error al cargar horarios: $err',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Solicitar Cita',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Seleccionar Fecha'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primaryTextColor,
                  ),
                ),
                trailing: Icon(Icons.calendar_today, color: secondaryTextColor),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'Seleccionar Hora'
                      : _selectedTime!.format(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primaryTextColor,
                  ),
                ),
                trailing: Icon(Icons.access_time, color: secondaryTextColor),
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Servicio',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  fillColor: cardColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: cardColor,
                style: TextStyle(color: primaryTextColor),
                items: _appointmentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona un tipo de servicio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentButtonColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Solicitar Cita',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestAppointment() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedServiceType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona fecha, hora y tipo de servicio.',
          ),
        ),
      );
      return;
    }

    final pb.RecordModel? currentUser = ref.read(currentUserRecordProvider);

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: No se pudo obtener la información de su usuario. Por favor, intente de nuevo o inicie sesión.',
          ),
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final endDateTime = startDateTime.add(const Duration(hours: 1));

    print('DEBUG: professionalProfileId: ${widget.professionalProfile.id}');
    print('DEBUG: clientId: ${currentUser.id}');
    print('DEBUG: selectedServiceType: $_selectedServiceType');
    print('DEBUG: startDateTime: $startDateTime');
    print('DEBUG: endDateTime: $endDateTime');

    final errorMessage = await ref
        .read(appointmentControllerProvider.notifier)
        .createAppointment(
          start: startDateTime,
          end: endDateTime,
          professionalProfileId: widget.professionalProfile.id,
          clientId: currentUser.id,
          service: _selectedServiceType!,
          originalFee: 0.0,
          status: 'Pendiente',
        );

    if (!mounted) {
      print(
        'Widget no montado, evitando interactuar con ScaffoldMessenger o Navigator.',
      );
      return;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al solicitar cita: $errorMessage')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cita solicitada exitosamente. Esperando confirmación del profesional.',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
