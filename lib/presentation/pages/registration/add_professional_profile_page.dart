import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/pages/home_page.dart';

const List<String> professionalCategories = [
  'Salud',
  'Legal',
  'Tecnología',
  'Asistencia',
  'Otro',
];

class AddProfessionalProfilePage extends ConsumerStatefulWidget {
  const AddProfessionalProfilePage({super.key});

  @override
  ConsumerState<AddProfessionalProfilePage> createState() =>
      _AddProfessionalProfilePageState();
}

class _AddProfessionalProfilePageState
    extends ConsumerState<AddProfessionalProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();

  String? _selectedCategory;
  LatLng? _selectedLocation;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final double? hourlyRate = double.tryParse(_hourlyRateController.text);
      final double? lat = _selectedLocation?.latitude;
      final double? lon = _selectedLocation?.longitude;

      if (hourlyRate == null ||
          lat == null ||
          lon == null ||
          _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa todos los campos requeridos.'),
          ),
        );
        return;
      }

      final errorMessage = await ref
          .read(registrationControllerProvider.notifier)
          .addProfessionalProfile(
            hourlyRate: hourlyRate,
            address: _addressController.text,
            description: _descriptionController.text,
            businessName: _businessNameController.text,
            coordinateLat: lat,
            coordinateLon: lon,
            category: _selectedCategory!,
          );

      if (errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } else {
        final authRepo = ref.read(authRepositoryProvider);
        final currentUser = ref.read(currentUserRecordProvider);

        if (currentUser != null) {
          await authRepo.addRoleToUser(currentUser.id, UserRole.professional);

          final refreshed = await authRepo.getUserById(currentUser.id);
          if (refreshed != null) {
            authRepo.pocketBase.authStore.save(
              authRepo.pocketBase.authStore.token,
              refreshed,
            );

            // invalidar dependencias
            ref.invalidate(currentUserRecordProvider);
            ref.invalidate(availableUserRolesProvider);
            ref.invalidate(activeRoleProvider);

            // setear rol activo como profesional
            ref.read(activeRoleProvider.notifier).state = UserRole.professional;
            ref.read(homeSectionProvider.notifier).state =
                HomeSection.professionalAppointments;
          }
        }

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil profesional agregado.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationControllerProvider);

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
    final cardAndInputFieldsColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;
    final primaryBackgroundColor = isDarkMode
        ? DarkAppColors.primaryBackground
        : LightAppColors.primaryBackground;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text("Crear Perfil Profesional"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Tarifa por Hora (BOB)",
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: "Dirección",
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Descripción Profesional",
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: "Nombre de Negocio (Opcional)",
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(-16.5, -68.15), // La Paz
                        initialZoom: 13,
                        onTap: (tapPos, point) {
                          setState(() {
                            _selectedLocation = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: "com.example.nexo",
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: "Categoría"),
                  items: professionalCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() {
                    _selectedCategory = val;
                  }),
                  validator: (value) =>
                      value == null ? "Selecciona una categoría" : null,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: registrationState.isLoading ? null : _submitForm,
                  child: registrationState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Finalizar Registro"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
