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
    final name = registrationDraft.fullName.trim();
    final first = name.isEmpty ? '' : name.split(' ').first;
    final headline = registrationDraft.canBook
        ? (first.isEmpty ? 'Ready when you are' : 'Hi $first, book in one tap')
        : 'India’s hub-first EV ride';
    return Scaffold(
      backgroundColor: Evuddy.wash,
      body: RefreshIndicator(
        color: Evuddy.green,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Evuddy.wash.withValues(alpha: 0.96),
              elevation: 0,
              title: const EvuddyLogo(height: 38),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Evuddy.greenSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        registrationDraft.apiOnline ? 'LIVE  ·  LKO' : 'LKO · KNP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Evuddy.greenDeep,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      'Swipe the photos · Book EV sits on the picture · GPS fleet',
                      style: GoogleFonts.plusJakartaSans(
                        color: Evuddy.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FleetHero(onBook: () => _book()),
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
                    const SizedBox(height: 22),
                    const RideSteps(),
                    const SizedBox(height: 24),
                    CampaignAdCarousel(onBook: () => _book()),
                    const SizedBox(height: 24),
                    Text('FARES', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${CatalogRates.gstNote} · swipe cards · tap to book',
                      style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    FareGrid(onPick: (fare) => _book(fare: fare)),
                    const SizedBox(height: 18),
                    const TrustStrip(),
                    const SizedBox(height: 28),
                    Text('NEARBY HUBS', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: hubs.isEmpty ? 1 : hubs.length,
                        separatorBuilder: (_, i) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          if (hubs.isEmpty) {
                            return SizedBox(
                              width: 240,
                              child: SurfaceCard(
                                child: Text(
                                  loadingHubs
                                      ? 'Finding live yards…'
                                      : 'No hub listed yet. Pull down to refresh.',
                                ),
                              ),
                            );
                          }
                          final h = hubs[i];
                          return SizedBox(
                            width: 248,
                            child: GestureDetector(
                              onTap: () {
                                registrationDraft.chosenCity = h.city;
                                registrationDraft.chosenHubId = h.id;
                                _book();
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(Evuddy.hubAsset, fit: BoxFit.cover),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.05),
                                              Colors.black.withValues(alpha: 0.78),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Evuddy.green,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'HUB ${h.code.isEmpty ? '' : h.code}',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            h.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            '${h.city} · ${h.location}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Book from this yard  →',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: const Color(0xFF86EFAC),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
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
                        },
                      ),
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
