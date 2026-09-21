import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'book_ev_screen.dart';
import 'login_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EvuddyHub> hubs = [];
  String? loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final online = await EvuddyApi.health();
      final h = await EvuddyApi.hubs();
      if (!mounted) return;
      setState(() {
        registrationDraft.apiOnline = online;
        hubs = h;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadError = 'Could not load live hubs.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      showBack: false,
      kicker: 'EVUDDY',
      title: 'Ride the city.\nOwn the journey.',
      subtitle:
          'The website landing page is marketing. This home is the rider desk: register once, then Book EV from a live hub.',
      footer: Column(
        children: [
          EvuddyButton(
            label: 'Book EV',
            onPressed: () {
              Navigator.push(context, evuddyRoute(const BookEvScreen()));
            },
          ),
          const SizedBox(height: 10),
          EvuddyGhostButton(
            label: 'Register / KYC',
            onPressed: () {
              Navigator.push(context, evuddyRoute(const LoginScreen()));
            },
          ),
        ],
      ),
      children: [
        Text('STARTING FARES', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Text(
          CatalogRates.gstNote,
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _FareChip(label: 'Hourly', value: '₹${CatalogRates.hourly}'),
            _FareChip(label: 'Daily', value: '₹${CatalogRates.daily}'),
            _FareChip(label: 'Weekly', value: '₹${CatalogRates.weekly}'),
            _FareChip(label: 'Monthly', value: '₹${CatalogRates.monthly}'),
            _FareChip(label: 'Rent to Own', value: '₹${CatalogRates.rtoDaily}/day'),
          ],
        ),
        const SizedBox(height: 24),
        Text('LIVE HUBS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        if (loadError != null) InfoNote(text: loadError!),
        if (hubs.isEmpty && loadError == null)
          const InfoNote(text: 'Loading hubs from evuddy.com…'),
        for (final h in hubs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${h.city} · ${h.location} · code ${h.code}',
                    style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FareChip extends StatelessWidget {
  const _FareChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Evuddy.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Evuddy.line),
        boxShadow: Evuddy.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Evuddy.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
