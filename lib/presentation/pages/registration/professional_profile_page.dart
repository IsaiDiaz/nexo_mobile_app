import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const List<String> professionalCategories = [
  'Salud',
  'Legal',
  'Tecnología',
  'Asistencia',
  'Otro',
];

class ProfessionalProfilePage extends ConsumerStatefulWidget {
  const ProfessionalProfilePage({super.key});

  @override
  ConsumerState<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState
    extends ConsumerState<ProfessionalProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _coordinateLatController =
      TextEditingController();
  final TextEditingController _coordinateLonController =
      TextEditingController();

  String? _selectedCategory;

  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();

    final registrationData = ref
        .read(registrationControllerProvider)
        .registrationData;
    _hourlyRateController.text = registrationData.hourlyRate?.toString() ?? '';
    _addressController.text = registrationData.address ?? '';
    _descriptionController.text = registrationData.description ?? '';
    _businessNameController.text = registrationData.businessName ?? '';
    _coordinateLatController.text =
        registrationData.coordinateLat?.toString() ?? '';
    _coordinateLonController.text =
        registrationData.coordinateLon?.toString() ?? '';
    _selectedCategory = registrationData.category;
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _businessNameController.dispose();
    _coordinateLatController.dispose();
    _coordinateLonController.dispose();
    super.dispose();
  }

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
          .setProfessionalProfileData(
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
        title: Text(
          'Perfil Profesional',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            ref.read(registrationControllerProvider.notifier).goBackStep();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Tarifa por Hora (BOB)',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentButtonColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu tarifa por hora';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Introduce una tarifa válida y positiva';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentButtonColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Descripción Profesional',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentButtonColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, describe tus servicios';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _businessNameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Nombre de Negocio (Opcional)',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentButtonColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          -16.5,
                          -68.15,
                        ), // La Paz por defecto
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
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: cardAndInputFieldsColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentButtonColor,
                        width: 2,
                      ),
                    ),
                  ),
                  style: TextStyle(color: primaryTextColor),
                  dropdownColor: cardAndInputFieldsColor,
                  items: professionalCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(color: primaryTextColor),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecciona una categoría';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: registrationState.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentButtonColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: registrationState.isLoading
                      ? CircularProgressIndicator(color: primaryTextColor)
                      : const Text(
                          'Finalizar Registro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (registrationState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      registrationState.errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
