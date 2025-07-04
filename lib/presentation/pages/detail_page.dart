// lib/presentation/pages/detail_page.dart
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperar los argumentos pasados durante la navegación
    // Asegúrate de que los argumentos sean un mapa, o ajusta el tipo según lo que pases
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String message = args?['message'] ?? 'No se recibió mensaje';

    return Scaffold(
      appBar: AppBar(title: const Text('Página de Detalle')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Estás en la página de detalle.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Mensaje recibido: $message',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Volver a la pantalla anterior
                Navigator.pop(context);
              },
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
