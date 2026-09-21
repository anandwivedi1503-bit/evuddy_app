import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Evuddy {
  static const black = Color(0xFF0B0D0C);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF6F6F6F);
  static const wash = Color(0xFFF4F4F4);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFE6E6E6);
  static const green = Color(0xFF00C853);
  static const greenDeep = Color(0xFF00A344);
  static const greenSoft = Color(0xFFECFBF1);
  static const cream = wash;

  static TextTheme _text(Color color) {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      displaySmall: GoogleFonts.manrope(
        fontSize: 34,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: color,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: color,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
        color: muted,
      ),
    );
  }

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: black,
        onPrimary: paper,
        secondary: green,
        surface: paper,
      ),
      textTheme: _text(ink),
    );
  }
}
