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
    required this.asset,
    this.plan = 'rental',
    this.featured = false,
  });

  final String id;
  final String label;
  final String price;
  final String unit;
  final String hint;
  final String asset;
  final String plan;
  final bool featured;
}

final fareOffers = <FareOffer>[
  FareOffer(
    id: 'Daily',
    label: 'Daily',
    price: CatalogRates.inr(CatalogRates.daily),
    unit: '/ day',
    hint: 'GST included',
    asset: Evuddy.yellowScooterAsset,
    featured: true,
  ),
  FareOffer(
    id: 'Weekly',
    label: 'Weekly',
    price: CatalogRates.inr(CatalogRates.weekly),
    unit: '/ week',
    hint: 'GST included',
    asset: Evuddy.riderCityAsset,
  ),
  FareOffer(
    id: 'Monthly',
    label: 'Monthly',
    price: CatalogRates.inr(CatalogRates.monthly),
    unit: '/ month',
    hint: 'GST included',
    asset: Evuddy.riderEveningAsset,
  ),
  FareOffer(
    id: 'Rent to Own',
    label: 'Rent to Own',
    price: CatalogRates.inr(CatalogRates.rtoDaily),
    unit: '/ day',
    hint: '${CatalogRates.rtoMonths} months · ${CatalogRates.inr(CatalogRates.securityDeposit)} hold',
    asset: Evuddy.yellowScooterAsset,
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
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          height: 168,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: featured ? Evuddy.green.withValues(alpha: 0.4) : Evuddy.line),
            boxShadow: const [
              BoxShadow(color: Color(0x0F0B1F14), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -8,
                child: Opacity(
                  opacity: 0.92,
                  child: Image.asset(
                    offer.asset,
                    width: 108,
                    height: 108,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          offer.label.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                            color: Evuddy.muted,
                          ),
                        ),
                        if (featured) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Evuddy.greenSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'POPULAR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Evuddy.greenDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      offer.price,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        height: 1,
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
                    const SizedBox(height: 4),
                    Text(
                      offer.hint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
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
