import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'book_ev_screen.dart';
import 'confirm_mobile_screen.dart';
import 'login_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<EvuddyHub> hubs = [];
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final online = await EvuddyApi.health();
      final h = await EvuddyApi.hubs();
      if (!mounted) return;
      setState(() {
        registrationDraft.apiOnline = online;
        hubs = h;
      });
    } catch (_) {}
  }

  void _book() {
    if (registrationDraft.phoneVerified && registrationDraft.canBook) {
      Navigator.push(context, evuddyRoute(const BookEvScreen()));
      return;
    }
    Navigator.push(context, evuddyRoute(const ConfirmMobileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.wash,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Evuddy.wash,
            elevation: 0,
            title: const EvuddyLogo(height: 40),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where are you\nriding today?',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hub pickup · Live GPS · EV only',
                    style: GoogleFonts.plusJakartaSans(
                      color: Evuddy.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedBuilder(
                    animation: _bob,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, (_bob.value - 0.5) * 10),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.asset(
                        Evuddy.scooterAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SurfaceCard(
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Evuddy.green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EVUDDY Electric Scooter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '120 km · 45 km/h · GPS live · 4h charge',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Evuddy.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EvuddyButton(label: 'Book EV', onPressed: _book),
                  const SizedBox(height: 10),
                  EvuddyGhostButton(
                    label: registrationDraft.phoneVerified
                        ? 'Update KYC'
                        : 'New rider · Register',
                    onPressed: () {
                      Navigator.push(context, evuddyRoute(const LoginScreen()));
                    },
                  ),
                  const SizedBox(height: 28),
                  Text('NEARBY HUBS', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: hubs.isEmpty ? 1 : hubs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        if (hubs.isEmpty) {
                          return const SizedBox(
                            width: 220,
                            child: SurfaceCard(child: Text('Loading live hubs…')),
                          );
                        }
                        final h = hubs[i];
                        return SizedBox(
                          width: 220,
                          child: SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${h.city} · ${h.location}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Evuddy.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Yard OTP after pay',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Evuddy.greenDeep,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('FARES', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Text(
                    CatalogRates.gstNote,
                    style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _Fare('Hourly', '₹60'),
                      _Fare('Daily', '₹230'),
                      _Fare('Weekly', '₹1,610'),
                      _Fare('Monthly', '₹6,900'),
                      _Fare('Rent to Own', '₹280/day'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fare extends StatelessWidget {
  const _Fare(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Evuddy.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Evuddy.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
