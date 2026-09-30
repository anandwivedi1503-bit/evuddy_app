import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../invest_screen.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

const heroPhotos = [
  Evuddy.yellowScooterAsset,
  Evuddy.riderCityAsset,
  Evuddy.riderEveningAsset,
];

/// Photo carousel only — Book EV lives in the Rapido-style search bar above.
class RideTodayHero extends StatefulWidget {
  const RideTodayHero({super.key});

  @override
  State<RideTodayHero> createState() => _RideTodayHeroState();
}

class _RideTodayHeroState extends State<RideTodayHero> {
  final page = PageController();
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % heroPhotos.length,
        duration: const Duration(milliseconds: 650),
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
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: PageView.builder(
              controller: page,
              onPageChanged: (i) => setState(() => index = i),
              itemCount: heroPhotos.length,
              itemBuilder: (context, i) {
                return Image.asset(
                  heroPhotos[i],
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(heroPhotos.length, (i) {
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

class OfferAd {
  const OfferAd({
    required this.kicker,
    required this.title,
    required this.body,
    required this.cta,
    required this.colors,
    this.darkText = false,
    this.pdf = true,
  });
  final String kicker;
  final String title;
  final String body;
  final String cta;
  final List<Color> colors;
  final bool darkText;
  final bool pdf;
}

const offerAds = [
  OfferAd(
    kicker: 'FLEET PARTNER',
    title: 'Own the fleet.\nWe operate everything.',
    body: 'FOCO · you own the EVs · EVUDDY runs riders, GPS and hub OTP',
    cta: 'See the program',
    colors: [Color(0xFFFFCC00), Color(0xFFFFE566)],
    darkText: true,
  ),
  OfferAd(
    kicker: 'LOW-SPEED  ·  5 SCOOTERS',
    title: '₹3,00,000',
    body: '₹15,000 / month  ·  ₹60,000 per scooter',
    cta: 'Open plan PDF',
    colors: [Color(0xFF14532D), Color(0xFF22C55E)],
  ),
  OfferAd(
    kicker: 'HIGH-SPEED  ·  5 SCOOTERS',
    title: '₹4,50,000',
    body: '₹18,000 / month  ·  ₹90,000 per scooter',
    cta: 'Open plan PDF',
    colors: [Color(0xFF9D174D), Color(0xFFE11D8F)],
  ),
];

class OfferAdCarousel extends StatefulWidget {
  const OfferAdCarousel({super.key, this.onBook});
  final VoidCallback? onBook;

  @override
  State<OfferAdCarousel> createState() => _OfferAdCarouselState();
}

class _OfferAdCarouselState extends State<OfferAdCarousel> {
  final page = PageController(viewportFraction: 0.92);
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % offerAds.length,
        duration: const Duration(milliseconds: 720),
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

  void _open(OfferAd ad) {
    Navigator.push(context, evuddyRoute(const InvestScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: offerAds.length,
            itemBuilder: (context, i) {
              final ad = offerAds[i];
              final ink = ad.darkText ? const Color(0xFF1C1917) : Colors.white;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _open(ad),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: ad.colors,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -28,
                          bottom: -28,
                          height: 200,
                          width: 200,
                          child: IgnorePointer(
                            child: Image.asset(
                              Evuddy.yellowScooterAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 100, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ink.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  ad.kicker,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                ad.title,
                                style: GoogleFonts.plusJakartaSans(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  height: 1.05,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ad.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: ink.withValues(alpha: 0.86),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: ad.darkText ? Colors.black : Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  ad.cta,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: ad.darkText ? Colors.white : Evuddy.greenDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
          children: List.generate(offerAds.length, (i) {
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
      (Icons.gps_fixed_rounded, 'Live GPS', 'Every scooter tracked'),
      (Icons.lock_rounded, 'Hub OTP', 'Pickup after first pay'),
      (Icons.credit_card_rounded, 'Razorpay', 'Same checkout as web'),
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
                  Icon(steps[i].$1, color: Evuddy.greenDeep, size: 22),
                  const SizedBox(height: 10),
                  Text(
                    steps[i].$2,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
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
