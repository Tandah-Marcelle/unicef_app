import 'package:flutter/material.dart';

class AppTheme {
  // Brand color constants
  static const Color unicefBlueSolid = Color(0xFF00AEEF);
  static const Color minproffGreen = Color(0xFF008751);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFF57C00);

  // Accessible light theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: unicefBlueSolid,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: const CardTheme(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: unicefBlueSolid,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black54),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: unicefBlueSolid,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: unicefBlueSolid,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48), // Ensure it fits the minimum touch target (48dp)
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: minproffGreen,
        foregroundColor: Colors.white,
      ),
      colorScheme: const ColorScheme.light(
        primary: unicefBlueSolid,
        secondary: minproffGreen,
        error: alertRed,
        surface: Colors.white,
      ),
    );
  }

  // Accessibility High-Contrast Dark Theme
  static ThemeData get highContrastDarkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.black,
      cardTheme: CardTheme(
        color: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.yellow, width: 2.0),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.yellow,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.yellow),
        titleTextStyle: TextStyle(
          color: Colors.yellow,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.yellow),
        titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.yellow),
        bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.yellow,
        thickness: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.yellow,
          minimumSize: const Size(88, 48), // Ensure it fits the minimum touch target (48dp)
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: Colors.yellow, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        foregroundColor: Colors.yellow,
        shape: CircleBorder(
          side: BorderSide(color: Colors.yellow, width: 2.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.yellow,
        size: 28,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.yellow,
        secondary: Colors.yellowAccent,
        error: Colors.redAccent,
        surface: Colors.black,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.black),
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.yellow;
          return Colors.white;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.yellow;
          return Colors.white;
        }),
      ),
    );
  }
}
