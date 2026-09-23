import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.invest = false,
    this.path,
    this.book = false,
  });
  final String kicker;
  final String title;
  final String body;
  final String cta;
  final bool invest;
  final String? path;
  final bool book;
}

const offerAds = [
  OfferAd(
    kicker: 'DEALER',
    title: 'Retail EVUDDY in your city',
    body: 'Showroom or pickup hub. ₹5 lakh minimum. KYC and yard OTP stay on our platform.',
    cta: 'Become a dealer',
    path: '/partners/dealer',
  ),
  OfferAd(
    kicker: 'FLEET PARTNER',
    title: 'Earn 60% of net profit',
    body: '₹1L · ₹5L · ₹10L for 42 months. Same math as the official poster.',
    cta: 'See investment plans',
    invest: true,
  ),
  OfferAd(
    kicker: 'DISTRIBUTOR',
    title: 'Supply dealers from ₹10 lakh',
    body: 'Territory warehouse, dealer onboarding and brand standards.',
    cta: 'Apply as distributor',
    path: '/partners',
  ),
  OfferAd(
    kicker: 'RIDERS',
    title: 'Hub OTP after first rupee',
    body: 'Razorpay on Book EV. GPS on every scooter. Lucknow & Kanpur.',
    cta: 'Book an EV',
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
          height: 168,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: offerAds.length,
            itemBuilder: (context, i) {
              final ad = offerAds[i];
              return GestureDetector(
                onTap: () => _open(ad),
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: BoxDecoration(
                    color: Evuddy.greenDeep,
                    borderRadius: BorderRadius.circular(22),
                  ),
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
                      Text(
                        '${ad.cta}  →',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
      (Icons.payments_outlined, 'Razorpay', 'Pay ₹1+ for yard OTP'),
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
