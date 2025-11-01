import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

final isLoadingLoginProvider = StateProvider<bool>((ref) => false);

final emailControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final passwordControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = ref.watch(emailControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);

    final isLoading = ref.watch(isLoadingLoginProvider);

    final formKey = GlobalKey<FormState>();

    Future<void> submitLogin() async {
      if (formKey.currentState!.validate()) {
        ref.read(isLoadingLoginProvider.notifier).state = true;

        final authController = ref.read(authControllerProvider.notifier);
        final errorMessage = await authController.signIn(
          emailController.text,
          passwordController.text,
        );

        ref.read(isLoadingLoginProvider.notifier).state = false;

        if (errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        } else {
          emailController.clear();
          passwordController.clear();
          formKey.currentState?.reset();
        }
      }
    }

    Future<void> loginOffline(BuildContext context, WidgetRef ref) async {
      final pinController = TextEditingController();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Acceso sin conexión'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'PIN de acceso',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.isEmpty) return;

                final auth = ref.read(authControllerProvider.notifier);
                final err = await auth.signInOffline(pin);

                Navigator.of(context).pop(); // cierra el diálogo

                if (err != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inicio de sesión offline exitoso'),
                    ),
                  );
                }
              },
              child: const Text('Acceder'),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appColors = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryTextColor = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final accentButtonColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;
    final primaryBackgroundColor = isDarkMode
        ? DarkAppColors.primaryBackground
        : LightAppColors.primaryBackground;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Nexo',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: primaryTextColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Email / Usuario',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: appColors,
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
                      return 'Por favor, introduce tu email o usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    fillColor: appColors,
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

                isLoading
                    ? CircularProgressIndicator(color: accentButtonColor)
                    : ElevatedButton(
                        onPressed: submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentButtonColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Acceder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => loginOffline(context, ref),
                  child: Text(
                    'Ingresar sin conexión',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    emailController.clear();
                    passwordController.clear();
                    formKey.currentState?.reset();

                    ref
                        .read(registrationControllerProvider.notifier)
                        .startRegistration();
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(color: secondaryTextColor),
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
