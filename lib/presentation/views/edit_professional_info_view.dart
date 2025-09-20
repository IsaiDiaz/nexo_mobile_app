import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:pocketbase/pocketbase.dart' as pb;

class EditProfessionalInfoView extends ConsumerStatefulWidget {
  const EditProfessionalInfoView({super.key});

  @override
  ConsumerState<EditProfessionalInfoView> createState() =>
      _EditProfessionalInfoViewState();
}

class _EditProfessionalInfoViewState
    extends ConsumerState<EditProfessionalInfoView> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _categoryController = TextEditingController();

  pb.RecordModel? _professionalProfile;
  bool _loading = true;

  LatLng? _selectedLocation;

  static const List<String> professionalCategories = [
    'Salud',
    'Legal',
    'Tecnología',
    'Asistencia',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    final profile = await authRepo.getProfessionalProfile(currentUser.id);
    _professionalProfile = profile;

    if (profile != null) {
      _businessNameController.text =
          profile.data['business_name']?.toString() ?? '';
      _descriptionController.text =
          profile.data['description']?.toString() ?? '';
      _addressController.text = profile.data['address']?.toString() ?? '';
      _hourlyRateController.text =
          profile.data['hourly_rate']?.toString() ?? '';
      _categoryController.text = profile.data['category']?.toString() ?? '';

      final coord = profile.data['coordinate'];
      if (coord != null && coord['lat'] != null && coord['lon'] != null) {
        _selectedLocation = LatLng(
          (coord['lat'] as num).toDouble(),
          (coord['lon'] as num).toDouble(),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _professionalProfile == null)
      return;

    final authRepo = ref.read(authRepositoryProvider);

    try {
      await authRepo.updateProfessionalProfile(
        recordId: _professionalProfile!.id,
        businessName: _businessNameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        hourlyRate: double.tryParse(_hourlyRateController.text),
        category: _categoryController.text,
        coordinateLat: _selectedLocation?.latitude,
        coordinateLon: _selectedLocation?.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil profesional actualizado.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar cambios: $e")));
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
    final backgroundColor = isDarkMode
        ? DarkAppColors.primaryBackground
        : LightAppColors.primaryBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Editar perfil profesional"),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accentButtonColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _businessNameController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _decoration(
                        "Nombre del negocio",
                        secondaryTextColor,
                        cardColor,
                        accentButtonColor,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Obligatorio" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: primaryTextColor),
                      maxLines: 3,
                      decoration: _decoration(
                        "Descripción",
                        secondaryTextColor,
                        cardColor,
                        accentButtonColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _addressController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _decoration(
                        "Dirección",
                        secondaryTextColor,
                        cardColor,
                        accentButtonColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _hourlyRateController,
                      style: TextStyle(color: primaryTextColor),
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        "Tarifa por hora (Bs.)",
                        secondaryTextColor,
                        cardColor,
                        accentButtonColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _categoryController.text.isNotEmpty
                          ? _categoryController.text
                          : null,
                      decoration: _decoration(
                        "Categoría",
                        secondaryTextColor,
                        cardColor,
                        accentButtonColor,
                      ),
                      dropdownColor: cardColor,
                      items: professionalCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(color: primaryTextColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoryController.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, selecciona una categoría";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    Text(
                      "Selecciona ubicación en el mapa",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                _selectedLocation ??
                                LatLng(-16.5, -68.15), // La Paz por defecto
                            initialZoom: 13,
                            onTap: (tapPosition, point) {
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
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentButtonColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Guardar cambios",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _decoration(
    String label,
    Color labelColor,
    Color fillColor,
    Color focusedColor,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      fillColor: fillColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 2),
      ),
    );
  }
}
