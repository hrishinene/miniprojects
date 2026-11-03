import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const ink = Color(0xFF143028);
  const paper = Color(0xFFF3FBF6);
  const leaf = Color(0xFF0C8F55);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: leaf,
        brightness: Brightness.light,
      ).copyWith(
        primary: leaf,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFD7F5E6),
        onPrimaryContainer: ink,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: leaf,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: leaf,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 48,
        height: 1.05,
        fontWeight: FontWeight.w600,
        color: leaf,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: ink),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.4,
        color: Color(0xFF245043),
      ),
    ),
  );
}
