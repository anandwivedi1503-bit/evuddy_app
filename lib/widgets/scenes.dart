import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../invest_screen.dart';
import '../open_link.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

class SceneSlide {
  const SceneSlide({required this.asset, required this.caption, required this.kicker});
  final String asset;
  final String caption;
  final String kicker;
}

const fleetScenes = [
  SceneSlide(asset: Evuddy.riderCityAsset, kicker: 'STREET', caption: 'City commute'),
  SceneSlide(asset: Evuddy.riderEveningAsset, kicker: 'EVENING', caption: 'After work'),
  SceneSlide(asset: Evuddy.sceneHomeAsset, kicker: 'HOME', caption: 'Parked at the gate'),
  SceneSlide(asset: Evuddy.hubAsset, kicker: 'YARD', caption: 'Hub pickup'),
  SceneSlide(asset: Evuddy.yellowScooterAsset, kicker: 'RANGE', caption: '120 km · full scooter'),
];

/// Official brand scenes, one after another. BoxFit.contain so the yellow
/// scooter is never cropped the way a cover-crop hero was.
class FleetSceneCarousel extends StatefulWidget {
  const FleetSceneCarousel({super.key, this.height = 248});
  final double height;

  @override
  State<FleetSceneCarousel> createState() => _FleetSceneCarouselState();
}

class _FleetSceneCarouselState extends State<FleetSceneCarousel> {
  final page = PageController();
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % fleetScenes.length,
        duration: const Duration(milliseconds: 680),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ColoredBox(
            color: const Color(0xFFF3EFE6),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: PageView.builder(
                controller: page,
                onPageChanged: (i) => setState(() => index = i),
                itemCount: fleetScenes.length,
                itemBuilder: (context, i) {
                  final s = fleetScenes[i];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 36),
                        child: Image.asset(
                          s.asset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 10,
                        child: Row(
                          children: [
                            Text(
                              s.kicker,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                                color: Evuddy.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.caption,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Evuddy.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(fleetScenes.length, (i) {
            final on = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: on ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: on ? Evuddy.green : Evuddy.line,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PosterAd {
  const PosterAd({
    required this.asset,
    required this.kicker,
    required this.onTapInvest,
    this.externalPath,
  });
  final String asset;
  final String kicker;
  final bool onTapInvest;
  final String? externalPath;
}

const posterAds = [
  PosterAd(asset: Evuddy.investPosterAsset, kicker: 'OFFICIAL POSTER · 60% SHARE', onTapInvest: true),
  PosterAd(
    asset: Evuddy.sceneDealerAsset,
    kicker: 'DEALER · ₹5 LAKH',
    onTapInvest: false,
    externalPath: '/partners/dealer',
  ),
  PosterAd(
    asset: Evuddy.sceneDistributorAsset,
    kicker: 'DISTRIBUTOR · ₹10 LAKH',
    onTapInvest: false,
    externalPath: '/partners',
  ),
  PosterAd(asset: Evuddy.sceneFranchiseAsset, kicker: 'FRANCHISE · APPLY ON SITE', onTapInvest: true),
];

class PosterAdCarousel extends StatefulWidget {
  const PosterAdCarousel({super.key});

  @override
  State<PosterAdCarousel> createState() => _PosterAdCarouselState();
}

class _PosterAdCarouselState extends State<PosterAdCarousel> {
  final page = PageController(viewportFraction: 0.86);
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % posterAds.length,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    page.dispose();
    super.dispose();
  }

  void _open(PosterAd ad) {
    if (ad.externalPath != null) {
      openEvuddyPath(ad.externalPath!);
      return;
    }
    Navigator.push(context, evuddyRoute(const InvestScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PARTNER POSTERS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Text(
          'Same artwork as evuddy.com — tap to read plans. No payment in the app.',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: posterAds.length,
            itemBuilder: (context, i) {
              final ad = posterAds[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _open(ad),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: Evuddy.ink,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            ad.asset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xE6000000)],
                                ),
                              ),
                              child: Text(
                                ad.kicker,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(posterAds.length, (i) {
            final on = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: on ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: on ? Evuddy.green : Evuddy.line,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RideSteps extends StatelessWidget {
  const RideSteps({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('01', 'Verify', 'OTP autofills from SMS'),
      ('02', 'Pick hub', 'Live Lucknow / Kanpur yards'),
      ('03', 'Ride', 'GPS on the scooter · yard OTP after pay'),
    ];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(
                color: Evuddy.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Evuddy.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[i].$1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.greenDeep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$2,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i].$3,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Evuddy.muted, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
