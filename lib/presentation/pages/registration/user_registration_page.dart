// lib/presentation/pages/registration/user_registration_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart'; // Asegúrate de tener la dependencia en pubspec.yaml

// StateProvider para la ruta temporal de la imagen seleccionada
final selectedAvatarPathProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

class UserRegistrationPage extends ConsumerWidget {
  UserRegistrationPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationState = ref.watch(registrationControllerProvider);
    final selectedAvatarPath = ref.watch(selectedAvatarPathProvider);

    // Precargar datos si ya existen en el controlador (ej. al volver atrás)
    _emailController.text = registrationState.registrationData.email ?? '';
    _passwordController.text =
        registrationState.registrationData.password ?? '';
    _usernameController.text =
        registrationState.registrationData.username ?? '';

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

    Future<void> _pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(selectedAvatarPathProvider.notifier).state = image.path;
      }
    }

    void _submitForm() {
      if (_formKey.currentState!.validate()) {
        ref
            .read(registrationControllerProvider.notifier)
            .setUserRegistrationData(
              email: _emailController.text,
              password: _passwordController.text,
              username: _usernameController.text,
              avatarPath: selectedAvatarPath,
            );
      }
    }

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Datos de Usuario',
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
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: cardAndInputFieldsColor,
                    backgroundImage: selectedAvatarPath != null
                        ? FileImage(File(selectedAvatarPath))
                        : null,
                    child: selectedAvatarPath == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: secondaryTextColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  selectedAvatarPath == null
                      ? 'Selecciona tu foto de perfil'
                      : 'Foto seleccionada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
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
                      return 'Por favor, introduce tu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Introduce un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Nombre de Usuario',
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
                      return 'Por favor, introduce tu nombre de usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
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
                      return 'Por favor, introduce tu contraseña';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentButtonColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Siguiente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
