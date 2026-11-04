import 'package:flutter/material.dart';

import '../theme/evuddy.dart';

/// Fleet partner hero: poster art with the **yellow** fleet scooter (not the green render baked into the PNG).
class FleetPartnerPoster extends StatelessWidget {
  const FleetPartnerPoster({super.key, this.height = 220});

  final double height;

  static const _wash = Color(0xFFF3EFE6);
  static const _washDeep = Color(0xFFEBF0E4);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              Evuddy.investPosterAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(-0.72, 0),
              filterQuality: FilterQuality.high,
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: height * 0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _wash.withValues(alpha: 0),
                      _wash,
                      _washDeep,
                    ],
                    stops: const [0, 0.35, 1],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 4, 10),
                  child: Image.asset(
                    Evuddy.yellowScooterAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
