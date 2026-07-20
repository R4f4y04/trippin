import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData nightOwl() {
    const navy = Color(0xFF0B0F1A);
    const deepNavy = Color(0xFF0A0C14);
    const electricPurple = Color(0xFF7C4DFF);
    const electricBlue = Color(0xFF3B82F6);
    const neonCyan = Color(0xFF22D3EE);
    const highContrastText = Color(0xFFE6E9F5);
    const mutedText = Color(0xFF9AA4C7);
    const surface = Color(0xFF121826);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: electricPurple,
      onPrimary: highContrastText,
      secondary: electricBlue,
      onSecondary: highContrastText,
      error: const Color(0xFFFF6B6B),
      onError: highContrastText,
      surface: surface,
      onSurface: highContrastText,
    );

    final textTheme = const TextTheme(
      displayLarge: TextStyle(color: highContrastText),
      displayMedium: TextStyle(color: highContrastText),
      displaySmall: TextStyle(color: highContrastText),
      headlineLarge: TextStyle(color: highContrastText),
      headlineMedium: TextStyle(color: highContrastText),
      headlineSmall: TextStyle(color: highContrastText),
      titleLarge: TextStyle(color: highContrastText),
      titleMedium: TextStyle(color: highContrastText),
      titleSmall: TextStyle(color: highContrastText),
      bodyLarge: TextStyle(color: highContrastText),
      bodyMedium: TextStyle(color: highContrastText),
      bodySmall: TextStyle(color: mutedText),
      labelLarge: TextStyle(color: highContrastText),
      labelMedium: TextStyle(color: highContrastText),
      labelSmall: TextStyle(color: mutedText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: navy,
      canvasColor: deepNavy,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepNavy,
        foregroundColor: highContrastText,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: highContrastText),
        actionTextColor: neonCyan,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electricPurple,
        foregroundColor: highContrastText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricPurple,
          foregroundColor: highContrastText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: mutedText),
      ),
    );
  }
}
