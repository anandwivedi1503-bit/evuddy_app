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

/// Matches the live product Home: photo, Book EV overlapping the bottom-left.
class RideTodayHero extends StatefulWidget {
  const RideTodayHero({super.key, required this.onBook});
  final VoidCallback onBook;

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
        Stack(
          clipBehavior: Clip.none,
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
            Positioned(
              left: 14,
              bottom: -18,
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: widget.onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: Evuddy.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: Evuddy.green.withValues(alpha: 0.45),
                  ),
                  child: Text(
                    'Book EV  →',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
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
    kicker: 'DEALER',
    title: 'Retail EVUDDY in your city',
    body: 'Showroom or pickup hub. ₹5 lakh minimum.',
    cta: 'Become a dealer',
    asset: Evuddy.sceneDealerAsset,
    path: '/partners/dealer',
  ),
  OfferAd(
    kicker: 'FLEET PARTNER',
    title: 'Earn 60% of net profit',
    body: '₹1L · ₹5L · ₹10L · 42 months. Download the brief.',
    cta: 'Open plans',
    asset: Evuddy.investPosterAsset,
    invest: true,
    pdf: true,
  ),
  OfferAd(
    kicker: 'DISTRIBUTOR',
    title: 'Supply dealers from ₹10 lakh',
    body: 'Territory warehouse and brand standards.',
    cta: 'Apply as distributor',
    asset: Evuddy.sceneDistributorAsset,
    path: '/partners',
  ),
  OfferAd(
    kicker: 'RIDERS',
    title: 'GST-in fares. Hub OTP after pay.',
    body: 'Daily ₹250 · GPS on every scooter.',
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

class _OfferAdCarouselState extends State<OfferAdCarousel> {
  final page = PageController();
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % offerAds.length,
        duration: const Duration(milliseconds: 600),
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

  void _open(OfferAd ad) {
    if (ad.book) {
      widget.onBook?.call();
      return;
    }
    if (ad.path != null) {
      openEvuddyPath(ad.path!);
      return;
    }
    Navigator.push(context, evuddyRoute(const InvestScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 214,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: offerAds.length,
            itemBuilder: (context, i) {
              final ad = offerAds[i];
              return Container(
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8)),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _open(ad),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        ad.asset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66050A08), Color(0xF2050A08)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad.kicker,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF86EFAC),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ad.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ad.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _open(ad),
                                    child: Text(
                                      '${ad.cta}  →',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                if (ad.pdf)
                                  TextButton.icon(
                                    onPressed: () => shareFleetPartnerPdf(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0x33FFFFFF),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                    label: Text(
                                      'PDF',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
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
      (Icons.sms_outlined, 'OTP autofill', 'SMS fills the 6 digits'),
      (Icons.mic_none_rounded, 'Voice KYC', 'Speak name, mobile, email'),
      (Icons.payments_outlined, 'Razorpay', 'Deposit hold or rent'),
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
