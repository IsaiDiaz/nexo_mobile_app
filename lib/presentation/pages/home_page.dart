// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Página Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido a la página principal!',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navegar a la página de detalle usando la ruta con nombre
                // Puedes pasar argumentos si necesitas
                Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: {
                    'message': 'Hola desde Home!',
                  }, // Ejemplo de argumento
                );
              },
              child: const Text('Ir a la Página de Detalle'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navegar a la página de detalle usando la ruta con nombre
                // Puedes pasar argumentos si necesitas
                Navigator.pushNamed(context, '/colors');
              },
              child: Text('Ir a la Página de Paleta de colores'),
            ),
            ElevatedButton(onPressed: () {}, child: Text('Log out')),
          ],
        ),
      ),
    );
  }
}
