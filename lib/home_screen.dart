import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'book_ev_screen.dart';
import 'confirm_mobile_screen.dart';
import 'invest_screen.dart';
import 'login_screen.dart';
import 'open_link.dart';
import 'ride_ready_screen.dart';
import 'state/registration_draft.dart';
import 'submitted_screen.dart';
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
    riderSessionTick.addListener(_onTick);
    _load();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    riderSessionTick.removeListener(_onTick);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final online = await EvuddyApi.health();
      final h = await EvuddyApi.hubs();
      if (registrationDraft.phoneVerified) {
        await registrationDraft.refreshFromServer();
      }
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
    if (registrationDraft.isPendingKyc) {
      Navigator.push(context, evuddyRoute(const SubmittedScreen()));
      return;
    }
    Navigator.push(context, evuddyRoute(const ConfirmMobileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
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
              title: const EvuddyLogo(height: 40),
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
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                        color: Evuddy.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hub pickup  ·  Live GPS  ·  EV only',
                      style: GoogleFonts.plusJakartaSans(
                        color: Evuddy.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    BookSearchBar(onBook: () => _book()),
                    if (d.activeBooking != null) ...[
                      const SizedBox(height: 14),
                      _LiveTripBanner(
                        booking: d.activeBooking!,
                        onOpen: () {
                          Navigator.push(context, evuddyRoute(const RideReadyScreen()));
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    const RideTodayHero(),
                    const SizedBox(height: 20),
                    OfferAdCarousel(onBook: () => _book()),
                    const SizedBox(height: 22),
                    Text('RIDE', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 10),
                    FareGrid(onPick: (fare) => _book(fare: fare)),
                    const SizedBox(height: 18),
                    const RideSteps(),
                    const SizedBox(height: 18),
                    QuickActions(
                      registerLabel: d.phoneVerified
                          ? (d.canBook ? 'Account' : 'KYC')
                          : 'Register',
                      onBook: () => _book(),
                      onRegister: () {
                        if (d.isPendingKyc) {
                          Navigator.push(context, evuddyRoute(const SubmittedScreen()));
                          return;
                        }
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
                    const SizedBox(height: 10),
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
                                                Color(0x99071B12),
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
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
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
                                                  color: Colors.white,
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

class BookSearchBar extends StatelessWidget {
  const BookSearchBar({super.key, required this.onBook});
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBook,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: Evuddy.rapidoYellow,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F59E0B),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.electric_moped_rounded, color: Evuddy.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book an EV',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Evuddy.ink,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Pickup at your hub',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Evuddy.ink,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Go',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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

class _LiveTripBanner extends StatelessWidget {
  const _LiveTripBanner({required this.booking, required this.onOpen});
  final RiderBooking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14532D), Color(0xFF16A34A)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.rideStatus == 'In Ride' ? 'Ride in progress' : 'Open booking',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    booking.hasPickupOtp
                        ? 'Pickup OTP ${booking.pickupOtp}'
                        : booking.bookingId,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
