import 'package:flutter/material.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: DarkAppColors.primaryBackground,
    canvasColor: DarkAppColors.primaryBackground,
    scaffoldBackgroundColor: DarkAppColors.primaryBackground,

    colorScheme: const ColorScheme.dark(
      primary: DarkAppColors.primaryBackground,
      onPrimary: DarkAppColors.primaryText,
      secondary: DarkAppColors.accentButton,
      onSecondary: Colors.black,
      surface: DarkAppColors.cardAndInputFields,
      onSurface: DarkAppColors.primaryText,
      error: Colors.red,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: DarkAppColors.primaryText),
      bodyMedium: TextStyle(color: DarkAppColors.primaryText),
      bodySmall: TextStyle(color: DarkAppColors.secondaryText),
      headlineLarge: TextStyle(color: DarkAppColors.primaryText),
      headlineMedium: TextStyle(color: DarkAppColors.primaryText),
      headlineSmall: TextStyle(color: DarkAppColors.primaryText),
      titleLarge: TextStyle(color: DarkAppColors.primaryText),
      titleMedium: TextStyle(color: DarkAppColors.primaryText),
      titleSmall: TextStyle(color: DarkAppColors.secondaryText),
      labelLarge: TextStyle(color: DarkAppColors.primaryText),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: DarkAppColors.primaryBackground,
      foregroundColor: DarkAppColors.primaryText,
      titleTextStyle: TextStyle(
        color: DarkAppColors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DarkAppColors.accentButton,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    cardTheme: CardThemeData(
      color: DarkAppColors.cardAndInputFields,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkAppColors.cardAndInputFields,
      hintStyle: TextStyle(color: DarkAppColors.secondaryText.withOpacity(0.7)),
      labelStyle: const TextStyle(color: DarkAppColors.primaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: DarkAppColors.accentButton, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: LightAppColors.primaryBackground,
    canvasColor: LightAppColors.primaryBackground,
    scaffoldBackgroundColor: LightAppColors.primaryBackground,

    colorScheme: const ColorScheme.light(
      primary: LightAppColors.primaryBackground,
      onPrimary: LightAppColors.primaryText,
      secondary: LightAppColors.accentButton,
      onSecondary: Colors.black,
      surface: LightAppColors.cardAndInputFields,
      onSurface: LightAppColors.primaryText,
      error: Colors.red,
      onError: Colors.white,
      brightness: Brightness.light,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: LightAppColors.primaryText),
      bodyMedium: TextStyle(color: LightAppColors.primaryText),
      bodySmall: TextStyle(color: LightAppColors.secondaryText),
      headlineLarge: TextStyle(color: LightAppColors.primaryText),
      headlineMedium: TextStyle(color: LightAppColors.primaryText),
      headlineSmall: TextStyle(color: LightAppColors.primaryText),
      titleLarge: TextStyle(color: LightAppColors.primaryText),
      titleMedium: TextStyle(color: LightAppColors.primaryText),
      titleSmall: TextStyle(color: LightAppColors.secondaryText),
      labelLarge: TextStyle(color: LightAppColors.primaryText),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: LightAppColors.primaryBackground,
      foregroundColor: LightAppColors.primaryText,
      titleTextStyle: TextStyle(
        color: LightAppColors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LightAppColors.accentButton,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    cardTheme: CardThemeData(
      color: LightAppColors.cardAndInputFields,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightAppColors.cardAndInputFields,
      hintStyle: TextStyle(
        color: LightAppColors.secondaryText.withOpacity(0.7),
      ),
      labelStyle: const TextStyle(color: LightAppColors.primaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: LightAppColors.accentButton, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
