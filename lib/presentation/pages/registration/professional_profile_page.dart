// lib/presentation/pages/registration/professional_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

// Categorías hardcodeadas por ahora, podrían venir de un backend en el futuro
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

  @override
  void initState() {
    super.initState();
    // Precargar datos si ya existen en el controlador
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
      final double? lat = double.tryParse(_coordinateLatController.text);
      final double? lon = double.tryParse(_coordinateLonController.text);

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
        // Mostrar SnackBar si hay error al finalizar el registro
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      // La redirección a HomePage se hará automáticamente por app.dart
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
                    labelText: 'Tarifa por Hora (USD)',
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
                  // No validator, ya que es opcional
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _coordinateLatController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: primaryTextColor),
                        decoration: InputDecoration(
                          labelText: 'Latitud',
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
                            return 'Introduce la latitud';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _coordinateLonController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: primaryTextColor),
                        decoration: InputDecoration(
                          labelText: 'Longitud',
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
                            return 'Introduce la longitud';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                  style: TextStyle(
                    color: primaryTextColor,
                  ), // Estilo del texto seleccionado
                  dropdownColor:
                      cardAndInputFieldsColor, // Color del menú desplegable
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
