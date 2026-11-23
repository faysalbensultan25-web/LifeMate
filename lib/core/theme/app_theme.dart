import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryBlue = Color(0xFF1877F2);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: const Color(0xFFF5F7FA),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1C1E21),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFE7F0FF),
    ),
  );
}
