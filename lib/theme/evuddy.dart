import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Evuddy {
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF6B7280);
  static const wash = Color(0xFFFFFFFF);
  static const paper = Color(0xFFFFFFFF);
  static const field = Color(0xFFF4F4F5);
  static const line = Color(0xFFE7E7E7);
  static const green = Color(0xFF16A34A);
  static const greenDeep = Color(0xFF15803D);
  static const magenta = Color(0xFFE11D8F);
  static const gold = magenta;
  static const greenSoft = Color(0xFFECFDF3);
  static const pinkSoft = Color(0xFFFDF2F8);
  static const cream = wash;
  static const black = ink;
  static const night = ink;
  static const danger = Color(0xFFDC2626);
  static const logoGreen = Color(0xFF22C55E);
  static const logoPink = Color(0xFFEC4899);
  static const lettersAsset = 'assets/images/evuddy_letters.png';

  static TextTheme _text(Color color) {
    return GoogleFonts.interTextTheme().copyWith(
      displaySmall: GoogleFonts.inter(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: color,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
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
      dividerColor: line,
    );
  }
}

/// Official letters lockup — only use large, never in a 32px header.
class EvuddyLogo extends StatelessWidget {
  const EvuddyLogo({super.key, this.height = 56});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Evuddy.lettersAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      alignment: Alignment.center,
    );
  }
}

/// Always-readable header mark: EV (green) + bolt + UDDY (pink).
class EvuddyMark extends StatelessWidget {
  const EvuddyMark({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'EV',
          style: GoogleFonts.inter(
            fontSize: size,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: Evuddy.logoGreen,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: size * 0.02, right: size * 0.02),
          child: Icon(
            Icons.bolt_rounded,
            size: size * 1.05,
            color: Evuddy.logoGreen,
          ),
        ),
        Text(
          'UDDY',
          style: GoogleFonts.inter(
            fontSize: size,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: Evuddy.logoPink,
          ),
        ),
      ],
    );
  }
}
