import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'confirm_mobile_screen.dart';
import 'ride_ready_screen.dart';
import 'state/registration_draft.dart';
import 'submitted_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class BookEvScreen extends StatefulWidget {
  const BookEvScreen({super.key, this.showBack = true});
  final bool showBack;

  @override
  State<BookEvScreen> createState() => _BookEvScreenState();
}

class _BookEvScreenState extends State<BookEvScreen> {
  List<EvuddyCity> cities = [];
  List<EvuddyHub> hubs = [];
  String? city;
  String? hubId;
  String? error;
  bool loading = true;

  bool get canBook =>
      registrationDraft.phoneVerified &&
      (registrationDraft.bookingEnabled ||
          registrationDraft.approvalStatus == 'Approved');

  bool get waitingKyc =>
      registrationDraft.phoneVerified &&
      !canBook &&
      (registrationDraft.approvalStatus == 'Under Review' ||
          registrationDraft.riderId != null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await EvuddyApi.cities();
      final h = await EvuddyApi.hubs();
      if (!mounted) return;
      setState(() {
        cities = c;
        hubs = h;
        city = registrationDraft.chosenCity ??
            (c.isEmpty ? null : c.first.name);
        hubId = registrationDraft.chosenHubId;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load cities and hubs from evuddy.com.';
      });
    }
  }

  List<EvuddyHub> get hubsInCity {
    if (city == null) return hubs;
    return hubs
        .where((h) => h.city.toLowerCase() == city!.toLowerCase())
        .toList();
  }

  void _pickPlan(String plan) {
    if (!registrationDraft.phoneVerified) {
      Navigator.push(context, evuddyRoute(const ConfirmMobileScreen()));
      return;
    }
    if (waitingKyc) {
      Navigator.push(context, evuddyRoute(const SubmittedScreen()));
      return;
    }
    if (!canBook) {
      Navigator.push(context, evuddyRoute(const ConfirmMobileScreen()));
      return;
    }
    setState(() => registrationDraft.chosenPlan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final plan = registrationDraft.chosenPlan;
    return AuthScreen(
      showBack: widget.showBack,
      kicker: 'Book EV',
      title: 'How do you want to ride?',
      subtitle:
          'Approved riders land here after OTP — same as the website. Pick rental or Rent to Own, then your hub.',
      error: error,
      footer: EvuddyButton(
        label: plan == null ? 'Choose a plan above' : 'Continue',
        onPressed: plan == null || hubId == null
            ? null
            : () {
                registrationDraft.chosenCity = city;
                registrationDraft.chosenHubId = hubId;
                Navigator.push(context, evuddyRoute(const RideReadyScreen()));
              },
      ),
      children: [
        const ScenePhoto(asset: Evuddy.yellowScooterAsset, height: 168),
        const SizedBox(height: 16),
        if (loading) const InfoNote(text: 'Loading live cities…'),
        if (!registrationDraft.phoneVerified)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: InfoNote(
              text: 'Website Book EV asks you to verify mobile first. Register / KYC unlocks checkout.',
            ),
          ),
        _PlanCard(
          frozen: plan == 'rto',
          tag: 'FLEXIBLE RENTAL',
          title: 'Normal booking',
          body: 'Hourly, daily, weekly or monthly. Return the scooter when the plan ends.',
          rates: const [
            'Hourly ₹${CatalogRates.hourly}',
            'Daily ₹${CatalogRates.daily}',
            'Weekly ₹${CatalogRates.weekly}',
            'Monthly ₹${CatalogRates.monthly}',
          ],
          onTap: () => _pickPlan('rental'),
          selected: plan == 'rental',
        ),
        const SizedBox(height: 12),
        _PlanCard(
          frozen: plan == 'rental',
          tag: 'OWN AFTER ${CatalogRates.rtoMonths} MONTHS',
          title: 'Rent to Own',
          body: '₹${CatalogRates.rtoDaily} / day · no security deposit. Ownership after a successful term.',
          rates: const ['Daily receipt', 'Hub OTP pickup'],
          onTap: () => _pickPlan('rto'),
          selected: plan == 'rto',
        ),
        const SizedBox(height: 24),
        Text('CITY', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        ChoicePills(
          options: cities.map((c) => c.name).toList(),
          value: city ?? (cities.isEmpty ? '' : cities.first.name),
          onChanged: (v) => setState(() {
            city = v;
            hubId = null;
          }),
        ),
        const SizedBox(height: 20),
        Text('HUB', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        if (hubsInCity.isEmpty)
          const InfoNote(text: 'No hub in this city yet.'),
        for (final h in hubsInCity)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => hubId = h.id),
              borderRadius: BorderRadius.circular(16),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Icon(
                      hubId == h.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: hubId == h.id ? Evuddy.green : Evuddy.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${h.name} · ${h.location}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tag,
    required this.title,
    required this.body,
    required this.rates,
    required this.onTap,
    required this.selected,
    required this.frozen,
  });

  final String tag;
  final String title;
  final String body;
  final List<String> rates;
  final VoidCallback onTap;
  final bool selected;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: frozen ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: frozen,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Evuddy.paper,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? Evuddy.green : Evuddy.line,
                  width: selected ? 1.7 : 1,
                ),
                boxShadow: Evuddy.lift,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    frozen ? 'FROZEN' : tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Evuddy.greenDeep,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in rates)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Evuddy.greenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            r,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
