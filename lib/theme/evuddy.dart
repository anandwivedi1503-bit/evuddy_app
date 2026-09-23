import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Evuddy {
  static const black = Color(0xFF1C1917);
  static const ink = Color(0xFF1C1917);
  static const muted = Color(0xFF78716C);
  static const wash = Color(0xFFF7F8F5);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFE8EDE8);
  static const green = Color(0xFF16A34A);
  static const greenDeep = Color(0xFF14532D);
  static const magenta = Color(0xFFE11D8F);
  static const gold = magenta;
  static const greenSoft = Color(0xFFECFDF3);
  static const pinkSoft = Color(0xFFFDF2F8);
  static const cream = wash;
  static const night = Color(0xFF050A08);
  static const danger = Color(0xFFB42318);

  static const splash = Color(0xFFFFFFFF);
  static const logoGreen = Color(0xFF22C55E);
  static const logoPink = Color(0xFFEC4899);

  static const wordmarkAsset = 'assets/images/evuddy_wordmark.png';
  static const logoMarkAsset = 'assets/images/evuddy_logo.png';
  static const riderCityAsset = 'assets/images/rider_city.png';
  static const riderEveningAsset = 'assets/images/rider_evening.png';
  static const yellowScooterAsset = 'assets/images/scooter_yellow.png';
  static const hubAsset = 'assets/images/scene_hub.jpg';
  static const scooterAsset = yellowScooterAsset;
  static const sceneHomeAsset = 'assets/images/scene_home.jpg';
  static const sceneDealerAsset = 'assets/images/scene_dealer.jpg';
  static const sceneDistributorAsset = 'assets/images/scene_distributor.jpg';
  static const sceneFranchiseAsset = 'assets/images/scene_franchise.jpg';
  static const sceneFilmAsset = 'assets/images/scene_film.jpg';
  static const investPosterAsset = 'assets/images/invest_poster.jpg';

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
        fontSize: 32,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: color,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w800,
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
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: green,
        onPrimary: paper,
        secondary: magenta,
        surface: paper,
      ),
      textTheme: _text(ink),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class EvuddyLogo extends StatelessWidget {
  const EvuddyLogo({super.key, this.height = 36, this.hero = false});
  final double height;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Evuddy.wordmarkAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class ScenePhoto extends StatelessWidget {
  const ScenePhoto({
    super.key,
    required this.asset,
    this.height = 210,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: const Color(0xFFF3EFE6),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              asset,
              fit: fit,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return const ColoredBox(color: Evuddy.night);
    }
    return const ColoredBox(color: Evuddy.wash);
  }
}
