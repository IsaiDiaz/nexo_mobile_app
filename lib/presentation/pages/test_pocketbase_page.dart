// lib/presentation/pages/test_pocketbase_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/test_pocketbase_controller.dart'; // Importa el nuevo controlador
import 'package:nexo/presentation/theme/app_colors.dart'; // Para los colores del tema

class TestPocketbasePage extends ConsumerWidget {
  const TestPocketbasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el estado del controlador
    final testState = ref.watch(testPocketbaseControllerProvider);

    // Lógica para obtener los colores del tema
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
                    ? null // Deshabilitar el botón si está cargando
                    : () {
                        // Llamar a la función para obtener usuarios
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
                    ? const CircularProgressIndicator(
                        color: Colors.black,
                      ) // Indicador de carga
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
                testState.message, // Mostrar el mensaje de estado/respuesta
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
