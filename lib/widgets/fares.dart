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
    this.asset,
  });

  final String id;
  final String label;
  final String price;
  final String unit;
  final String hint;
  final IconData icon;
  final String plan;
  final bool featured;
  final String? asset;
}

const fareOffers = <FareOffer>[
  FareOffer(
    id: 'Hourly',
    label: 'Hourly',
    price: '₹${CatalogRates.hourly}',
    unit: '/ hr',
    hint: 'Quick hops · +GST 5%',
    icon: Icons.schedule_rounded,
    asset: Evuddy.sceneHomeAsset,
  ),
  FareOffer(
    id: 'Daily',
    label: 'Daily',
    price: '₹${CatalogRates.daily}',
    unit: '/ day',
    hint: 'Most booked in Lucknow',
    icon: Icons.wb_sunny_outlined,
    featured: true,
    asset: Evuddy.riderCityAsset,
  ),
  FareOffer(
    id: 'Weekly',
    label: 'Weekly',
    price: '₹${CatalogRates.weekly}',
    unit: '/ wk',
    hint: '7 days · GPS fleet',
    icon: Icons.date_range_rounded,
    asset: Evuddy.riderEveningAsset,
  ),
  FareOffer(
    id: 'Monthly',
    label: 'Monthly',
    price: '₹${CatalogRates.monthly}',
    unit: '/ mo',
    hint: 'Work commute pack',
    icon: Icons.calendar_month_rounded,
    asset: Evuddy.hubAsset,
  ),
  FareOffer(
    id: 'Rent to Own',
    label: 'Rent to Own',
    price: '₹${CatalogRates.rtoDaily}',
    unit: '/ day',
    hint: '${CatalogRates.rtoMonths} months · no deposit · own it',
    icon: Icons.workspace_premium_outlined,
    plan: 'rto',
    asset: Evuddy.yellowScooterAsset,
  ),
];

class FareGrid extends StatelessWidget {
  const FareGrid({super.key, this.onPick});
  final ValueChanged<FareOffer>? onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) => SizedBox(
              width: 168,
              child: FareCard(offer: fareOffers[i], onTap: onPick),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
          height: wide ? 132 : 196,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: Evuddy.lift,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (offer.asset != null)
                  Image.asset(offer.asset!, fit: BoxFit.cover, alignment: Alignment.center),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: featured
                          ? const [Color(0x6614532D), Color(0xF014532D)]
                          : const [Color(0x33000000), Color(0xE6081210)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          if (featured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Evuddy.green,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'POPULAR',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        offer.price,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: wide ? 32 : 26,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${offer.unit}  ·  ${offer.hint}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to book  →',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF86EFAC),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
