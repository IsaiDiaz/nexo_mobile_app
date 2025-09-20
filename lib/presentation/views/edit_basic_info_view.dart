import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:pocketbase/pocketbase.dart' as pb;

final editSelectedAvatarPathProvider = StateProvider<String?>((ref) => null);

class EditBasicInformationView extends ConsumerStatefulWidget {
  const EditBasicInformationView({super.key});

  @override
  ConsumerState<EditBasicInformationView> createState() =>
      _EditBasicInformationViewState();
}

class _EditBasicInformationViewState
    extends ConsumerState<EditBasicInformationView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  pb.RecordModel? _personProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    final person = await authRepo.getPersonProfile(currentUser.id);

    _personProfile = person;

    _emailController.text = currentUser.data['email'] ?? '';
    _usernameController.text = currentUser.data['name'] ?? '';

    _firstNameController.text = person?.data['name'] ?? '';
    _lastNameController.text = person?.data['last_name'] ?? '';
    _phoneNumberController.text = person?.data['phone_number'] ?? '';

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      ref.read(editSelectedAvatarPathProvider.notifier).state = image.path;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: no hay usuario autenticado.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final bodyUser = {"name": _usernameController.text};

      final avatarPath = ref.read(editSelectedAvatarPathProvider);
      final files = <http.MultipartFile>[];
      if (avatarPath != null && avatarPath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
      }

      await authRepo.pocketBase
          .collection("users")
          .update(currentUser.id, body: bodyUser, files: files);

      if (_personProfile != null) {
        await authRepo.updatePersonProfile(
          recordId: _personProfile!.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneNumberController.text.isNotEmpty
              ? _phoneNumberController.text
              : null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cambios guardados exitosamente.")),
      );
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar cambios: $e")));
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text("Editar información básica"),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accentButtonColor))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
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

                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration(
                          "Email (no editable)",
                          secondaryTextColor,
                          cardAndInputFieldsColor,
                          accentButtonColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration(
                          "Nombre de usuario",
                          secondaryTextColor,
                          cardAndInputFieldsColor,
                          accentButtonColor,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "El nombre de usuario no puede estar vacío";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _firstNameController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration(
                          "Nombre(s)",
                          secondaryTextColor,
                          cardAndInputFieldsColor,
                          accentButtonColor,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "El nombre no puede estar vacío";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _lastNameController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration(
                          "Apellido(s)",
                          secondaryTextColor,
                          cardAndInputFieldsColor,
                          accentButtonColor,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "El apellido no puede estar vacío";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration(
                          "Teléfono (opcional)",
                          secondaryTextColor,
                          cardAndInputFieldsColor,
                          accentButtonColor,
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
