import 'package:flutter/material.dart';

class Evuddy {
  static const cream = Color(0xFFF4F8F1);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF101418);
  static const muted = Color(0xFF6A7368);
  static const line = Color(0xFFD8E2D4);
  static const green = Color(0xFF0B8A3A);
  static const greenSoft = Color(0xFFE7F6EB);
  static const gold = Color(0xFFC4A35A);

  static ThemeData theme() {
    const text = TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: Color(0xFF3D4639),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.light,
      ),
      textTheme: text,
      fontFamily: 'Roboto',
    );
  }
}
