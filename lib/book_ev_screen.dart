import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'confirm_mobile_screen.dart';
import 'ride_ready_screen.dart';
import 'services/nearby_hub.dart';
import 'state/registration_draft.dart';
import 'submitted_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/booking_ui.dart';
import 'widgets/chrome.dart';

class BookEvScreen extends StatefulWidget {
  const BookEvScreen({super.key, this.showBack = true});
  final bool showBack;

  @override
  State<BookEvScreen> createState() => _BookEvScreenState();
}

class _BookEvScreenState extends State<BookEvScreen> with WidgetsBindingObserver {
  List<EvuddyCity> cities = [];
  List<EvuddyHub> hubs = [];
  String? city;
  String? hubId;
  String? error;
  bool loading = true;
  bool refreshing = false;
  String? locationHint;
  Timer? _poll;

  bool get canBook => registrationDraft.canBook;

  bool get waitingKyc => registrationDraft.isPendingKyc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    riderSessionTick.addListener(_onTick);
    if (registrationDraft.canBook && registrationDraft.chosenPlan == null) {
      registrationDraft.chosenPlan = 'rental';
      registrationDraft.persist();
    }
    _load();
    _refreshApproval();
    _detectNearestHub();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) {
      if (waitingKyc) _refreshApproval();
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshApproval();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    riderSessionTick.removeListener(_onTick);
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refreshApproval() async {
    if (!registrationDraft.phoneVerified) return;
    if (refreshing) return;
    refreshing = true;
    await registrationDraft.refreshFromServer();
    refreshing = false;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _detectNearestHub() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            locationHint = 'Allow location to auto-pick the nearest hub (like Rapido).';
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (hubs.isEmpty) return;
      final pick = NearbyHub.nearest(
        hubs: hubs,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (pick.hub == null) return;
      registrationDraft
        ..chosenHubId = pick.hub!.id
        ..chosenCity = pick.city ?? pick.hub!.city;
      await registrationDraft.persist();
      if (!mounted) return;
      setState(() {
        hubId = pick.hub!.id;
        city = pick.city ?? pick.hub!.city;
        locationHint = 'Using nearest hub · ${pick.hub!.name} (from your location)';
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final c = await EvuddyApi.cities();
      final h = await EvuddyApi.hubs();
      if (!mounted) return;
      setState(() {
        cities = c;
        hubs = h;
        city = registrationDraft.chosenCity ?? (c.isEmpty ? null : c.first.name);
        hubId = registrationDraft.chosenHubId;
        loading = false;
        _ensureHub();
      });
      if (mounted) await _detectNearestHub();
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
    final match = hubs
        .where((h) => h.city.toLowerCase() == city!.toLowerCase())
        .toList();
    return match.isEmpty ? hubs : match;
  }

  void _ensureHub() {
    final listed = hubsInCity;
    if (listed.isEmpty) {
      hubId = null;
      return;
    }
    if (hubId != null && listed.any((h) => h.id == hubId)) return;
    hubId = listed.first.id;
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _continue() async {
    if (!canBook) {
      Navigator.push(
        context,
        evuddyRoute(
          waitingKyc ? const SubmittedScreen() : const ConfirmMobileScreen(),
        ),
      );
      return;
    }
    registrationDraft.chosenPlan ??= 'rental';
    _ensureHub();
    if (hubs.isEmpty && !loading) {
      await _load();
      _ensureHub();
    }
    if (hubId == null) {
      setState(() => error = 'Select a pickup hub, then tap Continue.');
      _toast('Select a pickup hub, then tap Continue.');
      return;
    }
    setState(() => error = null);
    final plan = registrationDraft.chosenPlan ?? 'rental';
    final duration = registrationDraft.chosenDuration;
    if (!registrationDraft.hasLiveBooking) {
      await registrationDraft.startFreshBooking();
    }
    await (registrationDraft
          ..chosenPlan = plan
          ..chosenDuration = duration
          ..chosenCity = city
          ..chosenHubId = hubId)
        .persist();
    if (!mounted) return;
    Navigator.push(
      context,
      evuddyRoute(const RideReadyScreen(startNew: true)),
    );
  }

  void _pickPlan(String plan) {
    if (!registrationDraft.phoneVerified) {
      Navigator.push(context, evuddyRoute(const ConfirmMobileScreen()));
      return;
    }
    if (registrationDraft.isRejected) {
      setState(() => error = 'This number was rejected. Call helpdesk.');
      _toast('This number was rejected. Call helpdesk.');
      return;
    }
    if (!registrationDraft.canBook) {
      Navigator.push(context, evuddyRoute(const SubmittedScreen()));
      return;
    }
    setState(() {
      error = null;
      registrationDraft.chosenPlan = plan;
    });
    registrationDraft.persist();
    _refreshApproval();
  }

  @override
  Widget build(BuildContext context) {
    final plan = registrationDraft.chosenPlan;
    return BookStage(
      showBack: widget.showBack,
      kicker: 'Book a ride',
      title: 'How do you want to ride?',
      subtitle: canBook
          ? 'Pick a plan, city and hub. Live scooters and Razorpay are next.'
          : 'Same catalog as evuddy.com — verify mobile, then reserve a scooter.',
      error: error,
      footer: EvuddyButton(
        sun: true,
        label: !canBook
            ? (waitingKyc ? 'Waiting for admin approval' : 'Verify mobile to book')
            : 'Continue to scooters',
        onPressed: _continue,
      ),
      children: [
        if (canBook) ...[
          RiderBadge(
            name: registrationDraft.fullName,
            phone: registrationDraft.phoneDisplay,
            riderId: registrationDraft.riderId,
            email: registrationDraft.email,
          ),
          const SizedBox(height: 16),
        ],
        if (registrationDraft.hasLiveBooking &&
            registrationDraft.activeBooking != null) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open trip ${registrationDraft.activeBooking!.bookingId}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'This number still has a trip on file. Resume it, or pick Normal / Rent to Own below for a new booking.',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, height: 1.4),
                ),
                const SizedBox(height: 10),
                EvuddyGhostButton(
                  label: 'Resume last trip',
                  onPressed: () => Navigator.push(
                    context,
                    evuddyRoute(const RideReadyScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (loading) const InfoNote(text: 'Loading live cities…'),
        if (locationHint != null && !loading) ...[
          InfoNote(text: locationHint!),
          const SizedBox(height: 12),
        ],
        if (waitingKyc)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InfoNote(
              text:
                  'Admin has not approved this rider yet (${registrationDraft.approvalStatus.isEmpty ? "Under Review" : registrationDraft.approvalStatus}). Booking unlocks after Approve.',
            ),
          )
        else if (!registrationDraft.phoneVerified)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: InfoNote(
              text: 'Razorpay after you reserve a live scooter. No PhonePe.',
            ),
          ),
        PlanSelectCard(
          tag: 'FLEXIBLE',
          title: 'Normal booking',
          price: CatalogRates.inr(CatalogRates.daily),
          unit: '/ day',
          body: 'Hourly to monthly. GST included. Return the scooter when the plan ends.',
          points: [
            'Hourly ${CatalogRates.inr(CatalogRates.hourly)}',
            'Weekly ${CatalogRates.inr(CatalogRates.weekly)}',
            'Monthly ${CatalogRates.inr(CatalogRates.monthly)}',
          ],
          selected: plan == 'rental',
          onTap: () => _pickPlan('rental'),
        ),
        const SizedBox(height: 12),
        PlanSelectCard(
          tag: 'OWN AFTER ${CatalogRates.rtoMonths} MONTHS',
          title: 'Rent to Own',
          price: CatalogRates.inr(CatalogRates.rtoDaily),
          unit: '/ day',
          body:
              '${CatalogRates.inr(CatalogRates.securityDeposit)} refundable hold. Full fare in one Razorpay pay. Hub OTP pickup.',
          points: const [
            '₹2,500 deposit',
            'One Razorpay pay',
            'Keep the scooter',
          ],
          selected: plan == 'rto',
          onTap: () => _pickPlan('rto'),
        ),
        const SizedBox(height: 22),
        if (canBook) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Evuddy.greenDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pickup near you',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'We save your chosen hub on evuddy.com when you continue — same as the website.',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                EvuddyGhostButton(
                  label: loading ? 'Loading hubs…' : 'Detect nearest hub',
                  onPressed: loading ? null : () async {
                    await _load();
                    await _detectNearestHub();
                    if (locationHint == null && mounted) {
                      _toast('Could not detect location. Pick city and hub manually.');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SectionLabel('City'),
        CityRail(
          cities: cities.map((c) => c.name).toList(),
          value: city,
          onChanged: (v) => setState(() {
            city = v;
            hubId = null;
            _ensureHub();
          }),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Pickup hub'),
        if (hubsInCity.isEmpty) const InfoNote(text: 'No hub in this city yet.'),
        for (final h in hubsInCity)
          HubSelectTile(
            hub: h,
            selected: hubId == h.id,
            onTap: () => setState(() => hubId = h.id),
          ),
      ],
    );
  }
}
