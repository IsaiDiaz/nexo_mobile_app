import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class PersonDetailsPage extends ConsumerWidget {
  PersonDetailsPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _identificationNumberController =
      TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationState = ref.watch(registrationControllerProvider);

    _firstNameController.text =
        registrationState.registrationData.firstName ?? '';
    _lastNameController.text =
        registrationState.registrationData.lastName ?? '';
    _phoneNumberController.text =
        registrationState.registrationData.phoneNumber ?? '';
    _identificationNumberController.text =
        registrationState.registrationData.identificationNumber ?? '';

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

    final isClient = registrationState.registrationData.role == UserRole.client;

    void submitForm() async {
      if (_formKey.currentState!.validate()) {
        ref
            .read(registrationControllerProvider.notifier)
            .setPersonDetailsData(
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              phoneNumber: _phoneNumberController.text.isNotEmpty
                  ? _phoneNumberController.text
                  : null,
              identificationNumber: _identificationNumberController.text,
            );

        if (isClient) {
          final errorMessage = await ref
              .read(registrationControllerProvider.notifier)
              .finalizeClientRegistration();
          if (errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Datos Personales',
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
                  controller: _firstNameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Nombre(s)',
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
                      return 'Por favor, introduce tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _lastNameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Apellido(s)',
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
                      return 'Por favor, introduce tu apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText:
                        'Número de Teléfono ${isClient ? "(Opcional)" : ""}',
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
                    if (!isClient && (value == null || value.isEmpty)) {
                      return 'Por favor, introduce tu número de teléfono';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _identificationNumberController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Número de Identificación (CI)',
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
                      return 'Por favor, introduce tu número de identificación';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: registrationState.isLoading ? null : submitForm,
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
                      : Text(
                          isClient ? 'Finalizar Registro' : 'Siguiente',
                          style: const TextStyle(
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
