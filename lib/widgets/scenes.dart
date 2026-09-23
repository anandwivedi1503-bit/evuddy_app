import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../invest_screen.dart';
import '../open_link.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

class SceneSlide {
  const SceneSlide({
    required this.asset,
    required this.kicker,
    required this.headline,
    required this.line,
  });
  final String asset;
  final String kicker;
  final String headline;
  final String line;
}

const fleetScenes = [
  SceneSlide(
    asset: Evuddy.riderCityAsset,
    kicker: 'LIVE IN THE CITY',
    headline: 'Yellow fleet. Zero tailpipe.',
    line: 'Lucknow & Kanpur hubs · GPS on every scooter',
  ),
  SceneSlide(
    asset: Evuddy.riderEveningAsset,
    kicker: 'AFTER WORK',
    headline: 'Ride home on EVUDDY.',
    line: 'Daily ₹230 · GST 5% on rent only',
  ),
  SceneSlide(
    asset: Evuddy.sceneHomeAsset,
    kicker: 'AT YOUR GATE',
    headline: 'Park. Charge. Go again.',
    line: 'Hub OTP after first rupee on Razorpay',
  ),
  SceneSlide(
    asset: Evuddy.hubAsset,
    kicker: 'YARD PICKUP',
    headline: 'Show OTP. Scooter unlocks.',
    line: 'Same checkout as evuddy.com',
  ),
  SceneSlide(
    asset: Evuddy.yellowScooterAsset,
    kicker: '120 KM RANGE',
    headline: 'The full yellow scooter.',
    line: '45 km/h · GPS · Rent or Rent to Own',
  ),
];

/// Peeking lifestyle carousel with Book EV on the photo (Rapido / Ola style).
class FleetHero extends StatefulWidget {
  const FleetHero({super.key, required this.onBook});
  final VoidCallback onBook;

  @override
  State<FleetHero> createState() => _FleetHeroState();
}

class _FleetHeroState extends State<FleetHero> {
  final page = PageController(viewportFraction: 0.92);
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % fleetScenes.length,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: fleetScenes.length,
            itemBuilder: (context, i) {
              final s = fleetScenes[i];
              final active = i == index;
              return AnimatedScale(
                scale: active ? 1 : 0.96,
                duration: const Duration(milliseconds: 280),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          s.asset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x33000000),
                                Color(0x14000000),
                                Color(0xE6000000),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  s.kicker,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                s.headline,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                  height: 1.15,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.line,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  onPressed: widget.onBook,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Evuddy.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Book EV',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(fleetScenes.length, (i) {
            final on = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: on ? 22 : 7,
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

class CampaignAd {
  const CampaignAd({
    required this.asset,
    required this.badge,
    required this.headline,
    required this.body,
    required this.cta,
    this.onTapInvest = false,
    this.externalPath,
  });
  final String asset;
  final String badge;
  final String headline;
  final String body;
  final String cta;
  final bool onTapInvest;
  final String? externalPath;
}

const campaignAds = [
  CampaignAd(
    asset: Evuddy.investPosterAsset,
    badge: 'FLEET PARTNER',
    headline: 'Earn 60% of net profit',
    body: '₹1L · ₹5L · ₹10L · 42 months. Official EVUDDY poster.',
    cta: 'See investment math',
    onTapInvest: true,
  ),
  CampaignAd(
    asset: Evuddy.sceneDealerAsset,
    badge: 'DEALER',
    headline: 'City showroom from ₹5 lakh',
    body: 'Retail scooters, Rent to Own intros, local service desk.',
    cta: 'Apply as dealer',
    externalPath: '/partners/dealer',
  ),
  CampaignAd(
    asset: Evuddy.sceneDistributorAsset,
    badge: 'DISTRIBUTOR',
    headline: 'Supply a territory from ₹10 lakh',
    body: 'Warehouse, dealer onboarding, brand standards.',
    cta: 'Apply as distributor',
    externalPath: '/partners',
  ),
  CampaignAd(
    asset: Evuddy.sceneFranchiseAsset,
    badge: 'FRANCHISE',
    headline: 'Run an EVUDDY desk in your city',
    body: 'Same partner form as the website. No payment in-app.',
    cta: 'Open partner form',
    onTapInvest: true,
  ),
  CampaignAd(
    asset: Evuddy.sceneFilmAsset,
    badge: 'RIDERS',
    headline: '#safeRideWithEvuddy',
    body: 'KYC · hub OTP · Razorpay · GPS. Built like a real fleet app.',
    cta: 'Book a scooter',
  ),
];

class CampaignAdCarousel extends StatefulWidget {
  const CampaignAdCarousel({super.key, this.onBook});
  final VoidCallback? onBook;

  @override
  State<CampaignAdCarousel> createState() => _CampaignAdCarouselState();
}

class _CampaignAdCarouselState extends State<CampaignAdCarousel> {
  final page = PageController(viewportFraction: 0.88);
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!page.hasClients) return;
      page.animateToPage(
        (index + 1) % campaignAds.length,
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

  void _open(CampaignAd ad) {
    if (ad.cta == 'Book a scooter' && widget.onBook != null) {
      widget.onBook!();
      return;
    }
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
        Text('OFFERS & PARTNERS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          'Swipe the ads · same artwork as evuddy.com',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 228,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: campaignAds.length,
            itemBuilder: (context, i) {
              final ad = campaignAds[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _open(ad),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(ad.asset, fit: BoxFit.cover, filterQuality: FilterQuality.high),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0x99000000), Color(0xE6081210)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Evuddy.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ad.badge,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                ad.headline,
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
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${ad.cta}  →',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF86EFAC),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
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
          children: List.generate(campaignAds.length, (i) {
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
                boxShadow: Evuddy.lift,
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
