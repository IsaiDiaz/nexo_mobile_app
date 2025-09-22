import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nexo/application/appointment_controller.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/application/appointment_type_controller.dart';
import 'package:nexo/application/professional_appointment_controller.dart';

class AddManualAppointmentSheet extends ConsumerStatefulWidget {
  const AddManualAppointmentSheet({super.key});

  @override
  ConsumerState<AddManualAppointmentSheet> createState() =>
      _AddManualAppointmentSheetState();
}

class _AddManualAppointmentSheetState
    extends ConsumerState<AddManualAppointmentSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedServiceType;
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final professional = await ref.read(professionalProfileProvider.future);
      if (professional != null) {
        ref
            .read(appointmentTypeControllerProvider.notifier)
            .loadAppointmentTypes(professional.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryText = isDark
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final cardColor = isDark
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;
    final accentButton = isDark
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;

    final typeState = ref.watch(appointmentTypeControllerProvider);
    final appointmentTypes = typeState.types;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: secondaryText.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Agregar cita manual",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Fecha
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? "Seleccionar fecha"
                      : DateFormat("dd/MM/yyyy").format(_selectedDate!),
                  style: TextStyle(color: primaryText),
                ),
                trailing: Icon(Icons.calendar_today, color: secondaryText),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),

              // Hora
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? "Seleccionar hora"
                      : _selectedTime!.format(context),
                  style: TextStyle(color: primaryText),
                ),
                trailing: Icon(Icons.access_time, color: secondaryText),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Comentarios
              TextField(
                controller: _commentsController,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  labelText: "Comentarios",
                  labelStyle: TextStyle(color: secondaryText),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Tipo de servicio
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: InputDecoration(
                  labelText: "Tipo de servicio",
                  labelStyle: TextStyle(color: secondaryText),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: appointmentTypes.map((type) {
                  final name = type.data['name'] as String? ?? 'Sin nombre';
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedServiceType = value),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _createManualAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentButton,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Guardar cita",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createManualAppointment() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa fecha, hora y tipo de servicio"),
        ),
      );
      return;
    }

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final end = start.add(const Duration(hours: 1));

    final professionalProfile = await ref.read(
      professionalProfileProvider.future,
    );

    if (professionalProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró tu perfil profesional.")),
      );
      return;
    }

    final error = await ref
        .read(professionalAppointmentControllerProvider.notifier)
        .createAppointment(
          start: start,
          end: end,
          professionalProfileId: professionalProfile.id,
          clientId: "",
          service: _selectedServiceType!,
          comments: _commentsController.text.trim(),
          originalFee: 0.0,
          status: "Confirmada",
        );

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cita manual creada exitosamente")),
      );
      Navigator.pop(context);
      ref
          .read(professionalAppointmentControllerProvider.notifier)
          .loadProfessionalAppointments();
    }
  }
}
