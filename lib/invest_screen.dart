import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'open_link.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

/// Same partner copy as evuddy.com/partners — shown in-app like a Rapido ad.
class InvestScreen extends StatelessWidget {
  const InvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      kicker: 'Partner  ·  Advertisement',
      title: 'Invest today. Earn monthly.',
      subtitle:
          'Same 60/40 model as the website. EVUDDY runs the fleet. You earn 60% of net profit for 42 months. No payment inside this app.',
      footer: EvuddyButton(
        label: 'Apply on evuddy.com',
        onPressed: () => openEvuddyPath('/partners'),
      ),
      children: [
        const ScenePhoto(asset: Evuddy.yellowScooterAsset, height: 168),
        const SizedBox(height: 16),
        const InfoNote(
          text:
              '3 scooters per ₹1 lakh, rented at ₹230 / 24 hrs. ₹87 profit per scooter per day after ops. You take ₹52.2 (60%).',
        ),
        const SizedBox(height: 18),
        Text('PLANS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        const _Plan(
          tag: 'STARTER',
          invest: '₹1 lakh',
          scooters: '3 scooters',
          monthly: '₹4,698 / month',
          total: '₹2,15,316 in 42 months',
          scrap: 'Scrap value ₹18,000',
        ),
        const SizedBox(height: 10),
        const _Plan(
          tag: 'GROWTH',
          invest: '₹5 lakh',
          scooters: '15 scooters',
          monthly: '₹23,490 / month',
          total: '₹10,76,580 in 42 months',
          scrap: 'Scrap value ₹90,000',
        ),
        const SizedBox(height: 10),
        const _Plan(
          tag: 'SCALE',
          invest: '₹10 lakh',
          scooters: '30 scooters',
          monthly: '₹46,980 / month',
          total: '₹21,53,160 in 42 months',
          scrap: 'Scrap value ₹1,80,000',
        ),
        const SizedBox(height: 18),
        Text('ALSO ON THE SITE', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        _LinkCard(
          title: 'EVUDDY Dealer',
          body: 'City showroom or pickup · ₹5 lakh minimum',
          onTap: () => openEvuddyPath('/partners/dealer'),
        ),
        const SizedBox(height: 8),
        _LinkCard(
          title: 'EVUDDY Distributor',
          body: 'Territory supply to dealers · ₹10 lakh minimum',
          onTap: () => openEvuddyPath('/partners'),
        ),
        const SizedBox(height: 14),
        Text(
          'Figures match the official poster on evuddy.com. Subject to operational performance.',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({
    required this.tag,
    required this.invest,
    required this.scooters,
    required this.monthly,
    required this.total,
    required this.scrap,
  });

  final String tag;
  final String invest;
  final String scooters;
  final String monthly;
  final String total;
  final String scrap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Evuddy.greenSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Evuddy.greenDeep,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                invest,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(scooters, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            monthly,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Evuddy.greenDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(total, style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13)),
          Text(scrap, style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.title, required this.body, required this.onTap});
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SurfaceCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: Evuddy.greenDeep, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
