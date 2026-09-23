import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/evuddy_api.dart';
import '../theme/evuddy.dart';

class FareOffer {
  const FareOffer({
    required this.id,
    required this.label,
    required this.price,
    required this.unit,
    required this.hint,
    required this.icon,
    this.plan = 'rental',
    this.featured = false,
  });

  final String id;
  final String label;
  final String price;
  final String unit;
  final String hint;
  final IconData icon;
  final String plan;
  final bool featured;
}

const fareOffers = <FareOffer>[
  FareOffer(
    id: 'Hourly',
    label: 'Hourly',
    price: '₹${CatalogRates.hourly}',
    unit: '/ hour',
    hint: '+ 5% GST',
    icon: Icons.schedule_rounded,
  ),
  FareOffer(
    id: 'Daily',
    label: 'Daily',
    price: '₹${CatalogRates.daily}',
    unit: '/ day',
    hint: 'Most booked',
    icon: Icons.wb_sunny_outlined,
    featured: true,
  ),
  FareOffer(
    id: 'Weekly',
    label: 'Weekly',
    price: '₹${CatalogRates.weekly}',
    unit: '/ week',
    hint: '+ 5% GST',
    icon: Icons.date_range_rounded,
  ),
  FareOffer(
    id: 'Monthly',
    label: 'Monthly',
    price: '₹${CatalogRates.monthly}',
    unit: '/ month',
    hint: '+ 5% GST',
    icon: Icons.calendar_month_rounded,
  ),
  FareOffer(
    id: 'Rent to Own',
    label: 'Rent to Own',
    price: '₹${CatalogRates.rtoDaily}',
    unit: '/ day',
    hint: '${CatalogRates.rtoMonths} months · no deposit',
    icon: Icons.workspace_premium_outlined,
    plan: 'rto',
  ),
];

class FareGrid extends StatelessWidget {
  const FareGrid({super.key, this.onPick});
  final ValueChanged<FareOffer>? onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: FareCard(offer: fareOffers[0], onTap: onPick)),
            const SizedBox(width: 10),
            Expanded(child: FareCard(offer: fareOffers[1], onTap: onPick)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: FareCard(offer: fareOffers[2], onTap: onPick)),
            const SizedBox(width: 10),
            Expanded(child: FareCard(offer: fareOffers[3], onTap: onPick)),
          ],
        ),
        const SizedBox(height: 10),
        FareCard(offer: fareOffers[4], wide: true, onTap: onPick),
      ],
    );
  }
}

class FareCard extends StatelessWidget {
  const FareCard({super.key, required this.offer, this.wide = false, this.onTap});
  final FareOffer offer;
  final bool wide;
  final ValueChanged<FareOffer>? onTap;

  @override
  Widget build(BuildContext context) {
    final featured = offer.featured;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!(offer);
              },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: featured ? Evuddy.green.withValues(alpha: 0.35) : Evuddy.line),
            boxShadow: const [
              BoxShadow(color: Color(0x0F0B1F14), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(offer.icon, size: 18, color: Evuddy.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      offer.label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: Evuddy.muted,
                      ),
                    ),
                  ),
                  if (featured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Evuddy.greenSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'POPULAR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Evuddy.greenDeep,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    offer.price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: wide ? 28 : 26,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      offer.unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Evuddy.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
