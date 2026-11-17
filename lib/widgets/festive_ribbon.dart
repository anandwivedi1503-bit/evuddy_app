import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/evuddy_api.dart';
import '../theme/evuddy.dart';

class FestiveRibbon extends StatelessWidget {
  const FestiveRibbon({super.key, required this.campaign});
  final BrandCampaign campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: campaign.accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: campaign.accent.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.welcomeTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Evuddy.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            campaign.ribbon,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Evuddy.ink,
            ),
          ),
        ],
      ),
    );
  }
}