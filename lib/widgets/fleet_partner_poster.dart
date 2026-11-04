import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/partner_pdf.dart';
import '../theme/evuddy.dart';

/// Fleet partner summary — no overlapping scooter photo (clean for Play / investors).
class FleetPartnerPoster extends StatelessWidget {
  const FleetPartnerPoster({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFCC00), Color(0xFFFFF4B8)],
        ),
        border: Border.all(color: Evuddy.ink.withValues(alpha: 0.08)),
        boxShadow: Evuddy.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EvuddyLogo(height: 36),
          const SizedBox(height: 14),
          Text(
            'Own the fleet. We operate.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.15,
              color: Evuddy.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'FOCO · Flexible ownership. Evuddy runs riders, GPS, KYC and hub OTP.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
              color: Evuddy.ink.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PlanChip(
                  label: 'Low-speed · 5 EVs',
                  value: CatalogRates.inr(FleetPartner.low.monthlyForFive),
                  sub: '/ month',
                  accent: Evuddy.greenDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanChip(
                  label: 'High-speed · 5 EVs',
                  value: CatalogRates.inr(FleetPartner.high.monthlyForFive),
                  sub: '/ month',
                  accent: Evuddy.magenta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
  });

  final String label;
  final String value;
  final String sub;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Evuddy.ink,
                  ),
                ),
                TextSpan(
                  text: sub,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Evuddy.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
