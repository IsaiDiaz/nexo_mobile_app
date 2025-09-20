import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

final editSelectedAvatarPathProvider = StateProvider<String?>((ref) => null);

class EditBasicInformationView extends ConsumerWidget {
  EditBasicInformationView({super.key});

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔹 Aquí luego cargarás los datos del usuario actual desde tu provider
    _emailController.text = "usuario@ejemplo.com";
    _usernameController.text = "usuario123";
    _firstNameController.text = "Nombre";
    _lastNameController.text = "Apellido";
    _phoneNumberController.text = "77777777";

    final selectedAvatarPath = ref.watch(editSelectedAvatarPathProvider);

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

    Future<void> pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(editSelectedAvatarPathProvider.notifier).state = image.path;
      }
    }

    void saveChanges() {
      if (_formKey.currentState!.validate()) {
        // Aquí luego integras con tu controlador para actualizar en el servidor/local
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cambios guardados exitosamente")),
        );
      }
    }

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text("Editar Información Básica"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
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

                // Email
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: _inputDecoration(
                    "Email",
                    secondaryTextColor,
                    cardAndInputFieldsColor,
                    accentButtonColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El email no puede estar vacío';
                    }
                    if (!value.contains('@')) {
                      return 'Introduce un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Nombre de usuario
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: _inputDecoration(
                    "Nombre de usuario",
                    secondaryTextColor,
                    cardAndInputFieldsColor,
                    accentButtonColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Nombres
                TextFormField(
                  controller: _firstNameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: _inputDecoration(
                    "Nombre(s)",
                    secondaryTextColor,
                    cardAndInputFieldsColor,
                    accentButtonColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Apellidos
                TextFormField(
                  controller: _lastNameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: _inputDecoration(
                    "Apellido(s)",
                    secondaryTextColor,
                    cardAndInputFieldsColor,
                    accentButtonColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Teléfono
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: primaryTextColor),
                  decoration: _inputDecoration(
                    "Teléfono",
                    secondaryTextColor,
                    cardAndInputFieldsColor,
                    accentButtonColor,
                  ),
                ),
                const SizedBox(height: 30),

                // Botón Guardar
                ElevatedButton(
                  onPressed: saveChanges,
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

  InputDecoration _inputDecoration(
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
