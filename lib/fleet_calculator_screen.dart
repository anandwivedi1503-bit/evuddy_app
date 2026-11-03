import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/fleet_calculator.dart';
import 'api/partner_pdf.dart';
import 'open_link.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

/// Rider / investor calculator only. Staff business planner lives on evuddy.com admin.
class FleetCalculatorScreen extends StatefulWidget {
  const FleetCalculatorScreen({
    super.key,
    this.highSpeed = false,
  });

  final bool highSpeed;

  @override
  State<FleetCalculatorScreen> createState() => _FleetCalculatorScreenState();
}

class _FleetCalculatorScreenState extends State<FleetCalculatorScreen> {
  late bool highSpeed;
  FleetInputKind kind = FleetInputKind.scooters;
  final scooters = TextEditingController(text: '${FleetPartner.minFleet}');
  final rupees = TextEditingController();

  @override
  void initState() {
    super.initState();
    highSpeed = widget.highSpeed;
  }

  @override
  void dispose() {
    scooters.dispose();
    rupees.dispose();
    super.dispose();
  }

  FleetLine get plan => highSpeed ? FleetPartner.high : FleetPartner.low;

  FleetQuote get quote {
    if (kind == FleetInputKind.rupees) {
      return FleetCalculator.fromRupees(
        plan: plan,
        rupees: FleetCalculator.parseAmount(rupees.text),
      );
    }
    return FleetCalculator.fromScooters(
      plan: plan,
      fleet: FleetCalculator.parseAmount(scooters.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return AuthScreen(
      kicker: 'Fleet partner',
      title: 'Estimate your fleet',
      subtitle:
          'Monthly return and fleet size from published numbers. Annual, 48-month and ops planning is staff-only on evuddy.com admin.',
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
        ChoicePills(
          options: const ['Low-speed', 'High-speed'],
          value: highSpeed ? 'High-speed' : 'Low-speed',
          onChanged: (v) => setState(() => highSpeed = v == 'High-speed'),
        ),
        const SizedBox(height: 12),
        ChoicePills(
          options: const ['Scooters', 'Rupees'],
          value: kind == FleetInputKind.rupees ? 'Rupees' : 'Scooters',
          onChanged: (v) => setState(() {
            kind = v == 'Rupees' ? FleetInputKind.rupees : FleetInputKind.scooters;
          }),
        ),
        const SizedBox(height: 16),
        if (kind == FleetInputKind.scooters)
          TextField(
            controller: scooters,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Number of scooters',
              helperText: 'Published minimum is ${FleetPartner.minFleet}',
              filled: true,
              fillColor: Evuddy.paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )
        else
          TextField(
            controller: rupees,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Investment amount (₹)',
              helperText:
                  '${CatalogRates.inr(plan.perScooter)} per scooter · leftover stays unallocated',
              filled: true,
              fillColor: Evuddy.paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        const SizedBox(height: 16),
        _QuoteCard(quote: q),
        if (!q.meetsMin && q.fleet > 0) ...[
          const SizedBox(height: 12),
          InfoNote(
            text:
                'Plans start at ${FleetPartner.minFleet} scooters. This estimate is shown so you can scale up before applying.',
          ),
        ],
        const SizedBox(height: 12),
        const InfoNote(
          text:
              'You own the scooters. EVUDDY operates them. Monthly return follows the published Fleet Partner brief — not a live payout in this app.',
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final FleetQuote quote;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote.plan.title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${quote.fleet} scooters',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          Text(
            '${CatalogRates.inr(quote.investment)} investment',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Evuddy.greenDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${CatalogRates.inr(quote.monthly)} / month',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'FOCO · EVUDDY operates · ${quote.termMonths} months',
            style: GoogleFonts.plusJakartaSans(
              color: Evuddy.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (quote.leftoverRupees > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${CatalogRates.inr(quote.leftoverRupees)} leftover — not enough for one more scooter.',
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
