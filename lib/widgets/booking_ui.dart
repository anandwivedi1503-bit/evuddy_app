import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/evuddy_api.dart';
import '../theme/evuddy.dart';
import 'chrome.dart';

/// Rapido-style booking canvas: yellow hero, cream body, sun CTA.
class BookStage extends StatelessWidget {
  const BookStage({
    super.key,
    required this.title,
    required this.children,
    this.kicker = 'BOOK EV',
    this.subtitle,
    this.showBack = true,
    this.footer,
    this.step,
    this.of = 4,
    this.error,
    this.hero,
  });

  final String title;
  final String kicker;
  final String? subtitle;
  final bool showBack;
  final List<Widget> children;
  final Widget? footer;
  final int? step;
  final int of;
  final String? error;
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF7F4EA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EA),
        body: Column(
          children: [
            _YellowHero(
              showBack: showBack,
              kicker: kicker,
              title: title,
              subtitle: subtitle,
              step: step,
              of: of,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  children: [
                    if (hero != null) ...[
                      hero!,
                      const SizedBox(height: 16),
                    ],
                    ...children,
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      _BookError(text: error!),
                    ],
                  ],
                ),
              ),
            ),
            if (footer != null)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    child: footer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _YellowHero extends StatelessWidget {
  const _YellowHero({
    required this.showBack,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.step,
    required this.of,
  });

  final bool showBack;
  final String kicker;
  final String title;
  final String? subtitle;
  final int? step;
  final int of;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Evuddy.rapidoYellow,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showBack)
                    _HeroIcon(
                      onTap: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                    )
                  else
                    ClipOval(
                      child: Image.asset(
                        Evuddy.appIconAsset,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: EvuddyLogo(height: 32),
                  ),
                  if (step != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Evuddy.ink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$step / $of',
                        style: GoogleFonts.plusJakartaSans(
                          color: Evuddy.rapidoYellow,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                kicker.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w800,
                  color: Evuddy.ink.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: Evuddy.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Evuddy.ink.withOpacity(0.72),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, size: 20, color: Evuddy.ink),
        ),
      ),
    );
  }
}

class FormDeck extends StatelessWidget {
  const FormDeck({
    super.key,
    required this.children,
    this.eyebrow,
    this.title,
    this.icon,
  });

  final List<Widget> children;
  final String? eyebrow;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Evuddy.rapidoYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: Evuddy.ink),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Text(
                            eyebrow!.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w800,
                              color: Evuddy.muted,
                            ),
                          ),
                        if (title != null)
                          Text(
                            title!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Evuddy.ink,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class PlanSelectCard extends StatelessWidget {
  const PlanSelectCard({
    super.key,
    required this.tag,
    required this.title,
    required this.price,
    required this.unit,
    required this.body,
    required this.points,
    required this.selected,
    required this.onTap,
  });

  final String tag;
  final String title;
  final String price;
  final String unit;
  final String body;
  final List<String> points;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? Evuddy.rapidoYellow : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? Evuddy.ink : Evuddy.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? const Color(0x55FFCC00) : const Color(0x14000000),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? Evuddy.ink : const Color(0xFFF3F0E4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: selected ? Evuddy.rapidoYellow : Evuddy.ink,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: Evuddy.ink,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Evuddy.ink,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: Evuddy.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Evuddy.ink.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Evuddy.ink.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in points)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withOpacity(0.55) : const Color(0xFFF7F4EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        p,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Evuddy.ink,
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

class CityRail extends StatelessWidget {
  const CityRail({
    super.key,
    required this.cities,
    required this.value,
    required this.onChanged,
  });

  final List<String> cities;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) {
      return const InfoNote(text: 'Cities load from evuddy.com.');
    }
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final name = cities[i];
          final sel = name == value;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(name);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 132,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sel ? Evuddy.rapidoYellow : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? Evuddy.ink : Evuddy.line, width: sel ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_city_rounded,
                    size: 20,
                    color: Evuddy.ink.withOpacity(0.8),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HubSelectTile extends StatelessWidget {
  const HubSelectTile({
    super.key,
    required this.hub,
    required this.selected,
    required this.onTap,
  });

  final EvuddyHub hub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFF4C2) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? Evuddy.ink : Evuddy.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? Evuddy.rapidoYellow : const Color(0xFFF7F4EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.place_rounded, color: Evuddy.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hub.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hub.location,
                        style: GoogleFonts.plusJakartaSans(
                          color: Evuddy.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: Evuddy.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DurationRail extends StatelessWidget {
  const DurationRail({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Hourly', CatalogRates.hourly, '/hr'),
      ('Daily', CatalogRates.daily, '/day'),
      ('Weekly', CatalogRates.weekly, '/wk'),
      ('Monthly', CatalogRates.monthly, '/mo'),
    ];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (label, price, unit) = items[i];
          final sel = label == value;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 118,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? Evuddy.rapidoYellow : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel ? Evuddy.ink : Evuddy.line, width: sel ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.ink.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CatalogRates.inr(price),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Evuddy.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RiderBadge extends StatelessWidget {
  const RiderBadge({
    super.key,
    required this.name,
    required this.phone,
    this.riderId,
    this.email,
  });

  final String name;
  final String phone;
  final String? riderId;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Evuddy.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Evuddy.rapidoYellow,
              shape: BoxShape.circle,
            ),
            child: Text(
              name.isEmpty ? 'R' : name[0].toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Rider' : name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  [phone, if (riderId != null && riderId!.isNotEmpty) riderId].join(' · '),
                  style: GoogleFonts.plusJakartaSans(
                    color: Evuddy.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (email != null && email!.isNotEmpty)
                  Text(
                    email!,
                    style: GoogleFonts.plusJakartaSans(
                      color: Evuddy.muted,
                      fontSize: 12,
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

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w800,
          color: Evuddy.muted,
        ),
      ),
    );
  }
}

class _BookError extends StatelessWidget {
  const _BookError({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: Evuddy.danger,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
