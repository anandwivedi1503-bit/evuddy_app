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
    this.asset = Evuddy.yellowScooterAsset,
    this.fit = BoxFit.contain,
    this.photoHeight = 104,
  });

  final String id;
  final String label;
  final String price;
  final String unit;
  final String hint;
  final String plan;
  final bool featured;
  final String asset;
  final BoxFit fit;
  final double photoHeight;
}

final fareOffers = <FareOffer>[
  FareOffer(
    id: 'Hourly',
    label: 'Hourly',
    price: CatalogRates.inr(CatalogRates.hourly),
    unit: 'per hour',
    hint: 'GST included',
    featured: true,
    asset: Evuddy.yellowScooterAsset,
    fit: BoxFit.contain,
  ),
  FareOffer(
    id: 'Daily',
    label: 'Daily',
    price: CatalogRates.inr(CatalogRates.daily),
    unit: 'per day',
    hint: 'GST included',
    asset: Evuddy.riderCityAsset,
    fit: BoxFit.cover,
  ),
  FareOffer(
    id: 'Weekly',
    label: 'Weekly',
    price: CatalogRates.inr(CatalogRates.weekly),
    unit: 'per week',
    hint: 'GST included',
    asset: Evuddy.riderEveningAsset,
    fit: BoxFit.cover,
  ),
  FareOffer(
    id: 'Monthly',
    label: 'Monthly',
    price: CatalogRates.inr(CatalogRates.monthly),
    unit: 'per month',
    hint: 'GST included',
    asset: Evuddy.sceneFilmAsset,
    fit: BoxFit.cover,
  ),
  FareOffer(
    id: 'Rent to Own',
    label: 'Own',
    price: CatalogRates.inr(CatalogRates.rtoDaily),
    unit: 'per day',
    hint: '${CatalogRates.rtoMonths} months · ${CatalogRates.inr(CatalogRates.securityDeposit)} hold',
    plan: 'rto',
    asset: Evuddy.yellowScooterAsset,
    fit: BoxFit.contain,
    photoHeight: 168,
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
        const SizedBox(height: 10),
        FareCard(offer: fareOffers[4], onTap: onPick),
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
                height: offer.photoHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: featured ? const Color(0xFFECFDF3) : const Color(0xFFF7F8F5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: Padding(
                    padding: offer.fit == BoxFit.contain
                        ? const EdgeInsets.all(8)
                        : EdgeInsets.zero,
                    child: Image.asset(
                      offer.asset,
                      fit: offer.fit,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
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
