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
      kicker: 'Fleet partner',
      title: 'Own the fleet.\nWe operate.',
      subtitle:
          'FOCO · start with 5 scooters. EVUDDY runs riders, GPS, KYC and hub OTP. Monthly return as published. Apply on evuddy.com — no invest payment in this app.',
      footer: Column(
        children: [
          EvuddyButton(
            label: 'Download investment PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: shareFleetPartnerPdf,
          ),
          const SizedBox(height: 10),
          EvuddyGhostButton(
            label: 'Apply on evuddy.com',
            onPressed: () => openEvuddyPath('/partners'),
          ),
        ],
      ),
      children: [
        const ScenePhoto(asset: Evuddy.yellowScooterAsset, height: 200, fit: BoxFit.contain),
        const SizedBox(height: 16),
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
        const SizedBox(height: 14),
        Text(
          'Scale tables (10–100 scooters) are in the PDF. Final terms: Fleet Partner Agreement with EVUDDY / Shubhrax Mobility Ltd.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF44403C),
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
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
        color: Colors.white,
        border: Border.all(color: accent, width: 1.6),
        boxShadow: Evuddy.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              tag,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: const Color(0xFF0C0A09),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            invest,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.8,
              color: const Color(0xFF0C0A09),
            ),
          ),
          Text(
            '5 scooters · $per each',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF292524),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$monthly / month',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Evuddy.greenDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'FOCO · EVUDDY operates · ${CatalogRates.partnerMonths} months',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF44403C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
