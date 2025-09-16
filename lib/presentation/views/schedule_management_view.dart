import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/schedule_controller.dart';
import 'package:nexo/model/available_schedule.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/application/auth_controller.dart';

class ScheduleManagementView extends ConsumerStatefulWidget {
  const ScheduleManagementView({super.key});

  @override
  ConsumerState<ScheduleManagementView> createState() =>
      _ScheduleManagementViewState();
}

class _ScheduleManagementViewState
    extends ConsumerState<ScheduleManagementView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _daysOfWeek = const [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final Map<String, String> _dayDisplayNames = const {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  Future<void> _addSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDay == null || _startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa todos los campos del horario.'),
          ),
        );
        return;
      }

      final now = DateTime.now();
      final startDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (startDateTime.isAtSameMomentAs(endDateTime) ||
          startDateTime.isAfter(endDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La hora de inicio debe ser anterior a la hora de fin.',
            ),
          ),
        );
        return;
      }

      final errorMessage = await ref
          .read(scheduleControllerProvider.notifier)
          .addSchedule(
            dayOfWeek: _selectedDay!,
            startTime: startDateTime,
            endTime: endDateTime,
          );

      if (errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } else {
        setState(() {
          _selectedDay = null;
          _startTime = null;
          _endTime = null;
          _formKey.currentState?.reset();
        });
      }
    }
  }

  Future<void> _editSchedule(AvailableSchedule schedule) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar horario para: ${schedule.id}')),
    );
  }

  Future<void> _confirmDeleteSchedule(String scheduleId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar este horario?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final errorMessage = await ref
          .read(scheduleControllerProvider.notifier)
          .deleteSchedule(scheduleId);
      if (errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
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
    final accentButtonColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;
    final cardColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    final professionalProfileAsync = ref.watch(professionalProfileProvider);
    final scheduleState = ref.watch(scheduleControllerProvider);
    final groupedSchedules = ref.watch(groupedSchedulesProvider);

    return professionalProfileAsync.when(
      data: (professionalProfile) {
        if (professionalProfile == null) {
          return Center(
            child: Text(
              'No tienes un perfil profesional configurado. Por favor, completa tu perfil profesional para gestionar horarios.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestionar Horarios de Disponibilidad',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: InputDecoration(
                        labelText: 'Día de la Semana',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        fillColor: cardColor,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      dropdownColor: cardColor,
                      style: TextStyle(color: primaryTextColor),
                      items: _daysOfWeek.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(_dayDisplayNames[day]!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecciona un día.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _startTime != null
                                  ? _startTime!.format(context)
                                  : '',
                            ),
                            decoration: InputDecoration(
                              labelText: 'Hora de Inicio',
                              labelStyle: TextStyle(color: secondaryTextColor),
                              fillColor: cardColor,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: secondaryTextColor,
                              ),
                            ),
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: accentButtonColor,
                                        secondary: accentButtonColor,
                                        onPrimary: Colors.black,
                                        onSurface: primaryTextColor,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != _startTime) {
                                setState(() {
                                  _startTime = picked;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona una hora de inicio.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _endTime != null
                                  ? _endTime!.format(context)
                                  : '',
                            ),
                            decoration: InputDecoration(
                              labelText: 'Hora de Fin',
                              labelStyle: TextStyle(color: secondaryTextColor),
                              fillColor: cardColor,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: secondaryTextColor,
                              ),
                            ),
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: accentButtonColor,
                                        secondary: accentButtonColor,
                                        onPrimary: Colors.black,
                                        onSurface: primaryTextColor,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != _endTime) {
                                setState(() {
                                  _endTime = picked;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona una hora de fin.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    scheduleState.isLoading
                        ? CircularProgressIndicator(color: accentButtonColor)
                        : ElevatedButton(
                            onPressed: _addSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentButtonColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Agregar Horario',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    if (scheduleState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          scheduleState.errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Mis Horarios Existentes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              scheduleState.isLoading && scheduleState.schedules.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : groupedSchedules.isEmpty
                  ? Center(
                      child: Text(
                        'No hay horarios registrados.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groupedSchedules.entries.map((entry) {
                        final dayName = entry.key;
                        final schedules = entry.value;
                        if (schedules.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 16),
                                ...schedules.map((schedule) {
                                  print('schedule: ${schedule.toJson()}');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${schedule.formattedStartTime} - ${schedule.formattedEndTime}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: primaryTextColor,
                                              ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red[400],
                                              ),
                                              onPressed: () =>
                                                  _confirmDeleteSchedule(
                                                    schedule.id,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentButtonColor),
            const SizedBox(height: 16),
            Text(
              'Cargando perfil profesional...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error al cargar perfil profesional: $err',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
        ),
      ),
    );
  }
}
