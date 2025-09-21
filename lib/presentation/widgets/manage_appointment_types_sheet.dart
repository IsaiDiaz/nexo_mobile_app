import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/appointment_type_controller.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class ManageAppointmentTypesSheet extends ConsumerStatefulWidget {
  const ManageAppointmentTypesSheet({super.key});

  @override
  ConsumerState<ManageAppointmentTypesSheet> createState() =>
      _ManageAppointmentTypesSheetState();
}

class _ManageAppointmentTypesSheetState
    extends ConsumerState<ManageAppointmentTypesSheet> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar tipos al abrir
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

    final state = ref.watch(appointmentTypeControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      expand: false,
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
                    color: secondaryTextColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Gestionar Tipos de Cita",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),

              // Input para nuevo tipo
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Nuevo tipo de cita...",
                        hintStyle: TextStyle(color: secondaryTextColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: primaryTextColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      final professional = await ref.read(
                        professionalProfileProvider.future,
                      );
                      if (professional == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No se encontró perfil profesional."),
                          ),
                        );
                        return;
                      }

                      final error = await ref
                          .read(appointmentTypeControllerProvider.notifier)
                          .createAppointmentType(
                            professionalId: professional.id,
                            name: name,
                          );

                      if (error == null) {
                        _nameController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tipo de cita creado con éxito."),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $error")),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentButtonColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (state.isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.secondary,
                  ),
                )
              else if (state.errorMessage != null)
                Text(
                  "Error: ${state.errorMessage}",
                  style: TextStyle(color: Colors.red),
                )
              else if (state.types.isEmpty)
                Text(
                  "Aún no has creado tipos de cita.",
                  style: TextStyle(color: secondaryTextColor),
                )
              else
                ...state.types.map((type) {
                  final typeName = type.data['name'] ?? 'Sin nombre';
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        typeName,
                        style: TextStyle(color: primaryTextColor),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final error = await ref
                              .read(appointmentTypeControllerProvider.notifier)
                              .deleteAppointmentType(type.id);

                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Tipo eliminado.")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $error")),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
