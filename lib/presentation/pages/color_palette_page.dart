import 'package:flutter/material.dart';

class ColorPalettePage extends StatelessWidget {
  const ColorPalettePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paletas de Colores de la App'),
        backgroundColor: const Color(0xFF0D2B3E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaletteSection(
              context,
              title: 'Paleta para Tema Oscuro',
              backgroundColor: const Color(0xFF0D2B3E),
              elements: [
                _ColorItem(
                  name: 'Fondo principal',
                  color: const Color(0xFF0D2B3E),
                  hex: '#0D2B3E',
                  textColor: Colors.white,
                ),
                _ColorItem(
                  name: 'Tarjetas y campos de entrada',
                  color: const Color(0xFF143F52),
                  hex: '#143F52',
                  textColor: Colors.white,
                ),
                _ColorItem(
                  name: 'Texto principal',
                  color: Colors.white,
                  hex: '#FFFFFF',
                  textColor: Colors.black,
                ),
                _ColorItem(
                  name: 'Botones destacados',
                  color: const Color(0xFFF4B942),
                  hex: '#F4B942',
                  textColor: Colors.black,
                ),
                _ColorItem(
                  name: 'Texto secundario',
                  color: const Color(0xFFD3D8DE),
                  hex: '#D3D8DE',
                  textColor: Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 40),

            _buildPaletteSection(
              context,
              title: 'Paleta para Tema Claro',
              backgroundColor: const Color(0xFFF6F9FC),
              elements: [
                _ColorItem(
                  name: 'Fondo principal',
                  color: const Color(0xFFF6F9FC),
                  hex: '#F6F9FC',
                  textColor: Colors.black,
                ),
                _ColorItem(
                  name: 'Tarjetas y campos',
                  color: const Color(0xFFE6F0F7),
                  hex: '#E6F0F7',
                  textColor: Colors.black,
                ),
                _ColorItem(
                  name: 'Texto principal',
                  color: const Color(0xFF0D2B3E),
                  hex: '#0D2B3E',
                  textColor: Colors.white,
                ),
                _ColorItem(
                  name: 'Botones destacados',
                  color: const Color(0xFFF4B942),
                  hex: '#F4B942',
                  textColor: Colors.black,
                ),
                _ColorItem(
                  name: 'Texto secundario',
                  color: const Color(0xFF4A5C66),
                  hex: '#4A5C66',
                  textColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteSection(
    BuildContext context, {
    required String title,
    required Color backgroundColor,
    required List<_ColorItem> elements,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: backgroundColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ...elements.map(
            (item) => _buildColorSwatch(
              item.name,
              item.color,
              item.hex,
              item.textColor,
              backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(
    String name,
    Color color,
    String hex,
    Color textColor,
    Color backgroundColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            color: color,
            child: Center(
              child: Text(
                'Color',
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: backgroundColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                Text(
                  hex,
                  style: TextStyle(
                    fontSize: 14,
                    color: backgroundColor.computeLuminance() > 0.5
                        ? Colors.grey[700]
                        : Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;
  final String hex;
  final Color textColor;

  _ColorItem({
    required this.name,
    required this.color,
    required this.hex,
    required this.textColor,
  });
}
