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
    this.plan = 'rental',
    this.featured = false,
  });

  final String id;
  final String label;
  final String price;
  final String unit;
  final String hint;
  final String plan;
  final bool featured;
}

final fareOffers = <FareOffer>[
  FareOffer(
    id: 'Daily',
    label: 'Daily',
    price: CatalogRates.inr(CatalogRates.daily),
    unit: 'per day',
    hint: 'GST included',
    featured: true,
  ),
  FareOffer(
    id: 'Weekly',
    label: 'Weekly',
    price: CatalogRates.inr(CatalogRates.weekly),
    unit: 'per week',
    hint: 'GST included',
  ),
  FareOffer(
    id: 'Monthly',
    label: 'Monthly',
    price: CatalogRates.inr(CatalogRates.monthly),
    unit: 'per month',
    hint: 'GST included',
  ),
  FareOffer(
    id: 'Rent to Own',
    label: 'Own',
    price: CatalogRates.inr(CatalogRates.rtoDaily),
    unit: 'per day',
    hint: '${CatalogRates.rtoMonths} mo · ${CatalogRates.inr(CatalogRates.securityDeposit)} hold',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: FareCard(offer: fareOffers[0], onTap: onPick)),
            const SizedBox(width: 10),
            Expanded(child: FareCard(offer: fareOffers[1], onTap: onPick)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: FareCard(offer: fareOffers[2], onTap: onPick)),
            const SizedBox(width: 10),
            Expanded(child: FareCard(offer: fareOffers[3], onTap: onPick)),
          ],
        ),
      ],
    );
  }
}

class FareCard extends StatelessWidget {
  const FareCard({super.key, required this.offer, this.onTap});
  final FareOffer offer;
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: featured ? Evuddy.green.withValues(alpha: 0.45) : Evuddy.line,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x0C0B1F14), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 88,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: featured ? const Color(0xFFECFDF3) : const Color(0xFFF7F8F5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Image.asset(
                    Evuddy.yellowScooterAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.label.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              letterSpacing: 0.9,
                              fontWeight: FontWeight.w800,
                              color: Evuddy.muted,
                            ),
                          ),
                        ),
                        if (featured)
                          Text(
                            'POPULAR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Evuddy.green,
                              letterSpacing: 0.4,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.price,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: Evuddy.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Evuddy.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Evuddy.greenDeep,
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
  }
}
