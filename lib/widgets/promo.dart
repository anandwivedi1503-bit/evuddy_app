import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../invest_screen.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

class InvestPromo {
  const InvestPromo({
    required this.kicker,
    required this.title,
    required this.body,
    required this.cta,
  });

  final String kicker;
  final String title;
  final String body;
  final String cta;
}

const investPromos = [
  InvestPromo(
    kicker: 'PARTNER AD',
    title: 'Invest ₹1 lakh. Earn monthly.',
    body: '3 yellow scooters · you keep 60% · 42 months. Same poster as evuddy.com.',
    cta: 'See plans',
  ),
  InvestPromo(
    kicker: 'DEALER',
    title: 'Retail EVUDDY in your city',
    body: 'Showroom or pickup hub. ₹5 lakh minimum. KYC and yard OTP stay on our platform.',
    cta: 'Become a dealer',
  ),
  InvestPromo(
    kicker: 'DISTRIBUTOR',
    title: 'Supply a whole territory',
    body: 'Onboard dealers, stock scooters and spares. ₹10 lakh minimum.',
    cta: 'Partner with us',
  ),
];

class InvestAdCarousel extends StatefulWidget {
  const InvestAdCarousel({super.key});

  @override
  State<InvestAdCarousel> createState() => _InvestAdCarouselState();
}

class _InvestAdCarouselState extends State<InvestAdCarousel> {
  final page = PageController();
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!page.hasClients) return;
      final next = (index + 1) % investPromos.length;
      page.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: page,
            onPageChanged: (i) => setState(() => index = i),
            itemCount: investPromos.length,
            itemBuilder: (context, i) {
              final p = investPromos[i];
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(context, evuddyRoute(const InvestScreen())),
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: i == 1
                              ? const [Color(0xFF1C1917), Color(0xFF14532D)]
                              : i == 2
                                  ? const [Color(0xFF3F0D2A), Color(0xFF9D174D)]
                                  : const [Color(0xFF052E16), Color(0xFF16A34A)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.kicker,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                p.cta,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            ],
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
          children: List.generate(investPromos.length, (i) {
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

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'KYC riders'),
      (Icons.lock_outline_rounded, 'Hub OTP'),
      (Icons.https_rounded, 'HTTPS'),
      (Icons.headset_mic_outlined, '24×7'),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Column(
              children: [
                Icon(item.$1, size: 20, color: Evuddy.greenDeep),
                const SizedBox(height: 6),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Evuddy.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
