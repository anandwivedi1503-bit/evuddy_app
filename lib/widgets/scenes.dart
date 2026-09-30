import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/partner_pdf.dart';
import '../invest_screen.dart';
import '../open_link.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

const heroPhotos = [
  Evuddy.riderCityAsset,
  Evuddy.riderEveningAsset,
  Evuddy.yellowScooterAsset,
  Evuddy.hubAsset,
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
    required this.asset,
    this.invest = false,
    this.path,
    this.book = false,
    this.pdf = false,
  });
  final String kicker;
  final String title;
  final String body;
  final String cta;
  final String asset;
  final bool invest;
  final String? path;
  final bool book;
  final bool pdf;
}

const offerAds = [
  OfferAd(
    kicker: 'FLEET PARTNER',
    title: '₹3,00,000  ·  ₹15,000 / month',
    body: '5 low-speed EVs. EVUDDY operates FOCO.',
    cta: 'Open FOCO plans',
    asset: Evuddy.investPosterAsset,
    invest: true,
    pdf: true,
  ),
  OfferAd(
    kicker: 'HIGH-SPEED',
    title: '₹4,50,000  ·  ₹18,000 / month',
    body: '5 high-speed scooters. EVUDDY runs operations.',
    cta: 'See high-speed',
    asset: Evuddy.investPosterAsset,
    invest: true,
    pdf: true,
  ),
  OfferAd(
    kicker: 'DAILY RIDE',
    title: '₹250 / day GST included',
    body: 'Hub OTP after Razorpay · live GPS on every scooter.',
    cta: 'Book an EV',
    asset: Evuddy.riderCityAsset,
    book: true,
  ),
];

class OfferAdCarousel extends StatefulWidget {
  const OfferAdCarousel({super.key, this.onBook});
  final VoidCallback? onBook;

  @override
  State<OfferAdCarousel> createState() => _OfferAdCarouselState();
}

class _OfferAdCarouselState extends State<OfferAdCarousel> with SingleTickerProviderStateMixin {
  final page = PageController(viewportFraction: 0.92);
  int index = 0;
  Timer? timer;
  late final AnimationController shine;

  @override
  void initState() {
    super.initState();
    shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
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
    shine.dispose();
    page.dispose();
    super.dispose();
  }

  void _open(OfferAd ad) {
    if (ad.book) {
      widget.onBook?.call();
      return;
    }
    final path = ad.path;
    if (path != null && path.isNotEmpty) {
      openEvuddyPath(path);
      return;
    }
    Navigator.push(context, evuddyRoute(const InvestScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 292,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: offerAds.length,
            itemBuilder: (context, i) {
              final ad = offerAds[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _open(ad),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ColoredBox(
                              color: const Color(0xFFF3EFE6),
                              child: Image.asset(
                                ad.asset,
                                fit: ad.invest ? BoxFit.contain : BoxFit.cover,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          Container(
                            color: const Color(0xFFF7F8F5),
                            padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ad.kicker,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Evuddy.greenDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ad.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF0C0A09),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ad.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF292524),
                                    fontSize: 13,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${ad.cta}  →',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Evuddy.greenDeep,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (ad.pdf)
                                      TextButton.icon(
                                        onPressed: shareFleetPartnerPdf,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Evuddy.greenDeep,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                        label: Text(
                                          'PDF',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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
          children: List.generate(offerAds.length, (i) {
            final on = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: on ? 8 : 6,
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
