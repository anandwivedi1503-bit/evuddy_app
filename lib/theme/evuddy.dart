import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Evuddy {
  static const black = Color(0xFF07110C);
  static const ink = Color(0xFF0B1220);
  static const muted = Color(0xFF64748B);
  static const wash = Color(0xFFF3F7F4);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8E4);
  static const green = Color(0xFF16A34A);
  static const greenDeep = Color(0xFF047857);
  static const magenta = Color(0xFFE11D8F);
  static const gold = magenta;
  static const greenSoft = Color(0xFFECFDF3);
  static const pinkSoft = Color(0xFFFDF2F8);
  static const cream = wash;
  static const night = Color(0xFF050A08);
  static const danger = Color(0xFFB42318);

  static const logoGreen = Color(0xFF22C55E);
  static const logoPink = Color(0xFFEC4899);

  static const wordmarkAsset = 'assets/images/evuddy_wordmark.png';
  static const scooterAsset = 'assets/images/evuddy_scooter.png';

  static List<BoxShadow> get lift => const [
        BoxShadow(
          color: Color(0x14071B12),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];

  static TextTheme _text(Color color) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: color,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: color,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
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
  const EvuddyLogo({super.key, this.height = 36, this.hero = true});
  final double height;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      Evuddy.wordmarkAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (!hero) return image;
    return Hero(
      tag: 'evuddy-wordmark',
      child: Material(type: MaterialType.transparency, child: image),
    );
  }
}

class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.75),
            radius: 1.25,
            colors: [Color(0xFF0C3B24), Evuddy.night],
          ),
        ),
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FBF8), Color(0xFFF3F7F4), Color(0xFFFDF6FA)],
        ),
      ),
    );
  }
}

class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    required this.color,
    required this.size,
    this.opacity = 0.55,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }
}

class EvuddyBoltMark extends StatelessWidget {
  const EvuddyBoltMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Evuddy.logoGreen, Color(0xFF059669), Evuddy.logoPink],
        ),
        boxShadow: [
          BoxShadow(
            color: Evuddy.logoGreen.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(painter: _BoltPainter()),
    );
  }
}

class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.58, h * 0.18)
      ..lineTo(w * 0.34, h * 0.52)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.40, h * 0.82)
      ..lineTo(w * 0.68, h * 0.46)
      ..lineTo(w * 0.52, h * 0.46)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
