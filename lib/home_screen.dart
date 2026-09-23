import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'book_ev_screen.dart';
import 'confirm_mobile_screen.dart';
import 'invest_screen.dart';
import 'login_screen.dart';
import 'open_link.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';
import 'widgets/fares.dart';
import 'widgets/promo.dart';
import 'widgets/scenes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EvuddyHub> hubs = [];
  bool loadingHubs = true;

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
        loadingHubs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingHubs = false);
    }
  }

  void _book({FareOffer? fare}) {
    if (fare != null) {
      registrationDraft.chosenPlan = fare.plan;
      registrationDraft.chosenDuration = fare.plan == 'rto' ? 'Rent to Own' : fare.id;
    }
    if (registrationDraft.phoneVerified && registrationDraft.canBook) {
      Navigator.push(context, evuddyRoute(const BookEvScreen()));
      return;
    }
    Navigator.push(context, evuddyRoute(const ConfirmMobileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: Evuddy.green,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: const EvuddyLogo(height: 36),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  tooltip: 'Call helpdesk',
                  onPressed: dialHelpdesk,
                  icon: const Icon(Icons.phone_outlined, color: Evuddy.ink),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where are you\nriding today?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: Evuddy.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hub pickup · Live GPS · EV only',
                      style: GoogleFonts.plusJakartaSans(
                        color: Evuddy.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RideTodayHero(onBook: () => _book()),
                    OfferAdCarousel(onBook: () => _book()),
                    const SizedBox(height: 22),
                    Text('PLANS', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      'GST included · same yellow EVUDDY scooter on every plan',
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    FareGrid(onPick: (fare) => _book(fare: fare)),
                    const SizedBox(height: 18),
                    QuickActions(
                      registerLabel: registrationDraft.phoneVerified ? 'KYC' : 'Register',
                      onBook: () => _book(),
                      onRegister: () {
                        Navigator.push(context, evuddyRoute(const LoginScreen()));
                      },
                      onInvest: () {
                        Navigator.push(context, evuddyRoute(const InvestScreen()));
                      },
                      onHelp: dialHelpdesk,
                    ),
                    const SizedBox(height: 18),
                    const TrustStrip(),
                    const SizedBox(height: 22),
                    Text('NEARBY HUBS', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Live yards on evuddy.com · tap to book',
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    if (hubs.isEmpty)
                      SurfaceCard(
                        child: Text(
                          loadingHubs
                              ? 'Finding live yards…'
                              : 'No hub listed yet. Pull down to refresh.',
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final h in hubs)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  registrationDraft.chosenCity = h.city;
                                  registrationDraft.chosenHubId = h.id;
                                  _book();
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: SizedBox(
                                    height: 196,
                                    width: double.infinity,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          Evuddy.hubAsset,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.center,
                                        ),
                                        const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0x11000000),
                                                Color(0xCC071B12),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  borderRadius: BorderRadius.circular(99),
                                                ),
                                                child: Text(
                                                  h.city.toUpperCase(),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.8,
                                                    color: Evuddy.greenDeep,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                h.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                h.location,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Book from this hub  →',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
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
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
