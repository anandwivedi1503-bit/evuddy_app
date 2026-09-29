import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/partner_pdf.dart';
import 'open_link.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class InvestScreen extends StatelessWidget {
  const InvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      kicker: 'Fleet partner  ·  FOCO',
      title: 'Own the fleet.\nWe operate everything.',
      subtitle:
          'Start with 5 EV scooters. EVUDDY runs riders, KYC, GPS, hub OTP and rentals. You receive the agreed monthly return. Apply on evuddy.com — no invest payment in this app.',
      footer: Column(
        children: [
          EvuddyButton(
            label: 'Download investment PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () {
              shareFleetPartnerPdf();
            },
          ),
          const SizedBox(height: 10),
          EvuddyGhostButton(
            label: 'Apply on evuddy.com',
            onPressed: () => openEvuddyPath('/partners'),
          ),
        ],
      ),
      children: [
        const ScenePhoto(asset: Evuddy.investPosterAsset, height: 240, fit: BoxFit.cover),
        const SizedBox(height: 16),
        const InfoNote(
          text:
              'FOCO model — you provide the asset, EVUDDY provides the operating system. Figures match the latest Fleet Partner Investment Program. Final terms are in the agreement with EVUDDY / Shubhrax Mobility Ltd.',
        ),
        const SizedBox(height: 18),
        Text('START WITH 5 EVs', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        _FocoCard(
          tag: 'LOW-SPEED',
          title: 'Low-speed EV scooter',
          invest: CatalogRates.inr(FleetPartner.low.invest(5)),
          monthly: CatalogRates.inr(FleetPartner.low.monthlyForFive),
          per: CatalogRates.inr(FleetPartner.low.perScooter),
          accent: Evuddy.green,
        ),
        const SizedBox(height: 10),
        _FocoCard(
          tag: 'HIGH-SPEED',
          title: 'High-speed EV scooter',
          invest: CatalogRates.inr(FleetPartner.high.invest(5)),
          monthly: CatalogRates.inr(FleetPartner.high.monthlyForFive),
          per: CatalogRates.inr(FleetPartner.high.perScooter),
          accent: Evuddy.magenta,
        ),
        const SizedBox(height: 18),
        Text('SCALE — LOW SPEED', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        for (final n in FleetPartner.fleets) ...[
          _ScaleRow(plan: FleetPartner.low, fleet: n),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        Text('SCALE — HIGH SPEED', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        for (final n in FleetPartner.fleets) ...[
          _ScaleRow(plan: FleetPartner.high, fleet: n),
          const SizedBox(height: 8),
        ],
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
          'Returns are proportionate to the published monthly plan and subject to the executed Fleet Partner Agreement. Not a guarantee.',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _FocoCard extends StatelessWidget {
  const _FocoCard({
    required this.tag,
    required this.title,
    required this.invest,
    required this.monthly,
    required this.per,
    required this.accent,
  });

  final String tag;
  final String title;
  final String invest;
  final String monthly;
  final String per;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.12), Colors.white],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: Evuddy.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            invest,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.8,
              color: Evuddy.ink,
            ),
          ),
          Text(
            'for 5 scooters · $per each',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            '$monthly / month',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Evuddy.greenDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'FOCO · 100% EVUDDY operations · ${CatalogRates.partnerMonths} months',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({required this.plan, required this.fleet});
  final FleetLine plan;
  final int fleet;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '$fleet',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          Expanded(
            child: Text(
              CatalogRates.inr(plan.invest(fleet)),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${CatalogRates.inr(plan.monthly(fleet))}/mo',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Evuddy.greenDeep,
            ),
          ),
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
