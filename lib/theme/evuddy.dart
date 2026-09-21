import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Evuddy {
  static const black = Color(0xFF0F172A);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const wash = Color(0xFFF8FAFC);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8F0);
  static const green = Color(0xFF16A34A);
  static const greenDeep = Color(0xFF15803D);
  static const magenta = Color(0xFFE11D8F);
  static const gold = magenta;
  static const greenSoft = Color(0xFFECFDF3);
  static const cream = wash;

  static const logoGreen = Color(0xFF22C55E);
  static const logoPink = Color(0xFFEC4899);

  static TextTheme _text(Color color) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        color: color,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: muted,
      ),
    );
  }

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: wash,
      colorScheme: const ColorScheme.light(
        primary: green,
        onPrimary: paper,
        secondary: magenta,
        surface: paper,
      ),
      textTheme: _text(ink),
    );
  }
}

class EvuddyLogo extends StatelessWidget {
  const EvuddyLogo({super.key, this.height = 36});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/evuddy_logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
