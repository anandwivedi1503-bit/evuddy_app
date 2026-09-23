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
      kicker: 'Fleet  ·  Advertisement',
      title: 'Invest today. Earn monthly.',
      subtitle:
          '60/40 with EVUDDY running the fleet for ${CatalogRates.partnerMonths} months. Daily rental ${CatalogRates.inr(CatalogRates.daily)} GST included. Apply on the website — no invest payment in this app.',
      footer: Column(
        children: [
          EvuddyButton(
            label: 'Download partner PDF',
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
        const ScenePhoto(asset: Evuddy.investPosterAsset, height: 280, fit: BoxFit.cover),
        const SizedBox(height: 16),
        InfoNote(
          text:
              '${CatalogRates.scootersPerLakh} scooters per ₹1 lakh, rented at ${CatalogRates.inr(CatalogRates.daily)} / day GST included. About ${CatalogRates.inr(CatalogRates.investorPerScooterDay)} to you per scooter per day (60% of net).',
        ),
        const SizedBox(height: 18),
        Text('PLANS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        _Plan(tag: 'STARTER', lakhs: 1),
        const SizedBox(height: 10),
        _Plan(tag: 'GROWTH', lakhs: 5),
        const SizedBox(height: 10),
        _Plan(tag: 'SCALE', lakhs: 10),
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
          'Subject to operational performance. Rider catalog matches this app and evuddy.com Book EV.',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({required this.tag, required this.lakhs});
  final String tag;
  final int lakhs;

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
                CatalogRates.inr(lakhs * 100000),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${CatalogRates.scootersPerLakh * lakhs} scooters',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${CatalogRates.inr(CatalogRates.investorMonthly(lakhs))} / month',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Evuddy.greenDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${CatalogRates.inr(CatalogRates.investorTerm(lakhs))} in ${CatalogRates.partnerMonths} months',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
          ),
          Text(
            'Scrap value ${CatalogRates.inr(CatalogRates.scrapValue(lakhs))}',
            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
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
