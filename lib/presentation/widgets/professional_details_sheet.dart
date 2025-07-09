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
import 'package:nexo/application/chat_controller.dart'; // Importar el controlador de chat
import 'package:nexo/presentation/views/chat_detail_view.dart'; // Importar la vista de detalle del chat
import 'package:nexo/presentation/pages/home_page.dart'; // Para navegar a la sección de mensajes
import 'package:nexo/model/registration_data.dart';

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
  String? _selectedServiceType;

  final List<String> _appointmentTypes = [
    'Consulta',
    'Sesión',
    'Asesoría',
    'Clase',
  ];

  // Reutiliza la función del avatar para obtener el avatar del usuario asociado al perfil profesional
  String? _getProfessionalUserAvatarUrl(
    pb.RecordModel professionalProfile,
    WidgetRef ref,
  ) {
    // Asumimos que 'professionalProfile' tiene un campo 'user' expandido que es el RecordModel del usuario.
    final userRecord = professionalProfile.expand['user']?.first;
    if (userRecord != null) {
      final avatar = userRecord.data['avatar'] as String?;
      if (avatar != null && avatar.isNotEmpty) {
        final pocketBase = ref.read(authRepositoryProvider).pocketBase;
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

    // Obtener el RecordModel del usuario asociado al perfil profesional
    // Esto asume que tienes 'user' expandido en tu consulta de profesionales
    final pb.RecordModel? professionalUserRecord =
        widget.professionalProfile.expand['user']?.first;

    final professionalName =
        professionalUserRecord?.data['name'] as String? ?? 'Nombre Desconocido';
    final professionalDescription =
        widget.professionalProfile.data['description'] as String? ??
        'No hay descripción.';
    final professionalLocation =
        widget.professionalProfile.data['address'] as String? ??
        'Ubicación no especificada.';

    final LatLng? professionalCoordinates = _getCoordinates(
      widget.professionalProfile,
    );

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

    // Obtener el avatar del profesional usando la nueva función
    final professionalAvatarUrl = _getProfessionalUserAvatarUrl(
      widget.professionalProfile,
      ref,
    );

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
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: professionalAvatarUrl != null
                        ? NetworkImage(professionalAvatarUrl)
                        : null,
                    child: professionalAvatarUrl == null
                        ? Text(
                            professionalName.isNotEmpty
                                ? professionalName[0].toUpperCase()
                                : 'P',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professionalName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.professionalProfile.data['business_name']
                                  as String? ??
                              'Negocio Desconocido',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          widget.professionalProfile.data['category']
                                  as String? ??
                              'Sin Categoría',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Descripción:',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                professionalDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, color: secondaryTextColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      professionalLocation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
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
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: secondaryTextColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: professionalCoordinates,
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.nexo',
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
              // Aquí va el botón de chat, antes de la sección de solicitar cita
              // Asegúrate de que el usuario actual es un cliente para mostrar este botón
              // (o que no sea el mismo profesional intentando chatear consigo mismo)
              Consumer(
                // Usamos Consumer para acceder a activeRoleProvider
                builder: (context, ref, child) {
                  final activeRole = ref.watch(activeRoleProvider);
                  final currentUser = ref.watch(currentUserRecordProvider);

                  // Solo mostrar el botón de chat si el usuario actual es un cliente
                  // y no está intentando chatear consigo mismo (si el profesional es el mismo usuario)
                  if (activeRole == UserRole.client &&
                      currentUser != null &&
                      professionalUserRecord?.id != currentUser.id) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(
                                context,
                              ).pop(); // Cierra el bottom sheet
                              final chat = await ref
                                  .read(chatControllerProvider.notifier)
                                  .initiateChatWithProfessional(
                                    professionalUserRecord!.id,
                                  ); // Usar el ID del usuario del profesional

                              if (chat != null && context.mounted) {
                                // Si el chat se inició o se encontró, navegar a la sección de mensajes
                                // y luego a la vista de detalle del chat
                                // Primero navega a la HomePage y asegura que la sección sea 'messages'
                                final homeNavigator = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                );
                                homeNavigator.popUntil(
                                  (route) => route.isFirst,
                                ); // Asegura que estemos en la raíz de la navegación
                                ref
                                    .read(homeSectionProvider.notifier)
                                    .state = HomeSection
                                    .messages; // Establece la sección de mensajes

                                // Espera un pequeño momento para que la UI de HomePage se actualice
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );

                                // Luego, empuja la vista de detalle del chat
                                if (context.mounted) {
                                  // Verificar de nuevo si el contexto sigue montado
                                  homeNavigator.push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatDetailView(chat: chat),
                                    ),
                                  );
                                }
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ref
                                              .read(chatControllerProvider)
                                              .errorMessage ??
                                          'No se pudo iniciar el chat.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Enviar Mensaje'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: Colors.white,
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ), // Espacio entre el botón de chat y solicitar cita
                      ],
                    );
                  }
                  return const SizedBox.shrink(); // No muestra el botón si no es cliente o es el mismo profesional
                },
              ),
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
    // ... (Tu lógica existente para solicitar cita)
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
