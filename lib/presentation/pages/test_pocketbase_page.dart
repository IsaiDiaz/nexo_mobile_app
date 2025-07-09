import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/test_pocketbase_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class TestPocketbasePage extends ConsumerWidget {
  const TestPocketbasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testState = ref.watch(testPocketbaseControllerProvider);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final accentButtonColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;
    final primaryBackgroundColor = isDarkMode
        ? DarkAppColors.primaryBackground
        : LightAppColors.primaryBackground;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Prueba de Conexión a PocketBase',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: testState.isLoading
                    ? null
                    : () {
                        ref
                            .read(testPocketbaseControllerProvider.notifier)
                            .fetchUsers();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentButtonColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: testState.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Obtener Usuarios de PocketBase',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 30),
              Text(
                testState.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: primaryTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
