import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api/evuddy_api.dart';
import '../api/razorpay_checkout.dart';
import '../state/registration_draft.dart';
import '../theme/evuddy.dart';
import '../widgets/chrome.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  Timer? _poll;

  List<EvuddyCity> cities = [];
  List<EvuddyHub> hubs = [];
  List<EvuddyVehicle> vehicles = [];
  List<RideHistoryItem> rides = [];
  List<PaymentReceipt> receipts = [];
  List<SupportTicket> tickets = [];
  RiderBooking? live;
  bool loading = true;
  String? error;
  String? note;

  int reviewStars = 5;
  final reviewComment = TextEditingController();
  RideHistoryItem? reviewTarget;
  bool busy = false;

  WebViewController? map;
  bool mapReady = false;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    tabs.addListener(() {
      if (!tabs.indexIsChanging) setState(() {});
    });
    _load();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    tabs.dispose();
    reviewComment.dispose();
    super.dispose();
  }

  Future<String?> _token() => registrationDraft.freshToken(force: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final c = await EvuddyApi.cities();
      final h = await EvuddyApi.hubs();
      final v = await EvuddyApi.vehicles();
      List<RideHistoryItem> history = [];
      List<PaymentReceipt> rec = [];
      List<SupportTicket> tix = [];
      RiderBooking? mine;
      final token = await _token();
      if (token != null) {
        try {
          mine = await EvuddyApi.myBooking(token);
          if (mine != null) registrationDraft.applyActiveBooking(mine);
        } catch (_) {}
        try {
          history = await EvuddyApi.bookingHistory(token);
        } catch (_) {}
        try {
          rec = await EvuddyApi.myReceipts(token);
        } catch (_) {}
        try {
          tix = await EvuddyApi.myTickets(token);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        cities = c;
        hubs = h;
        vehicles = v;
        rides = history;
        receipts = rec;
        tickets = tix;
        live = mine ?? registrationDraft.activeBooking;
        loading = false;
      });
      _pushMap();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _ensureMap() async {
    if (map != null) return;
    final html = await DefaultAssetBundle.of(context).loadString('assets/iot/map.html');
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFEEF2EF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            mapReady = true;
            _pushMap();
          },
        ),
      );
    await controller.loadHtmlString(html, baseUrl: 'https://www.evuddy.com');
    map = controller;
    if (mounted) setState(() {});
  }

  Future<void> _pushMap() async {
    await _ensureMap();
    final ctrl = map;
    if (ctrl == null || !mapReady) return;
    final points = <Map<String, dynamic>>[];
    for (final h in hubs) {
      final lat = h.latitude;
      final lng = h.longitude;
      if (lat != null && lng != null && lat >= 6 && lat <= 37 && lng >= 68 && lng <= 98) {
        points.add({
          'lat': lat,
          'lng': lng,
          'label': 'Hub ${h.name} · ${h.location}',
          'kind': 'hub',
        });
      }
    }
    if (points.isEmpty) {
      points.add({
        'lat': 26.8467,
        'lng': 80.9462,
        'label': hubs.isEmpty ? 'EVUDDY Lucknow hub' : 'Hub ${hubs.first.name} (Lucknow)',
        'kind': 'hub',
      });
    }
    for (final v in vehicles) {
      if (v.hasGps) {
        points.add({
          'lat': v.latitude,
          'lng': v.longitude,
          'label': 'Scooter ${v.displayId} · ${v.batteryPercentage.round()}%',
          'kind': 'vehicle',
        });
      }
    }
    final b = live;
    if (b != null) {
      final lat = b.latitude;
      final lng = b.longitude;
      if (lat != null &&
          lng != null &&
          lat >= 6 &&
          lat <= 37 &&
          lng >= 68 &&
          lng <= 98) {
        points.add({
          'lat': lat,
          'lng': lng,
          'label': 'Rider ${b.bookingId}',
          'kind': 'rider',
        });
      } else if (points.isNotEmpty && (b.inRide || b.readyForPickup)) {
        points.add({
          'lat': points.first['lat'],
          'lng': points.first['lng'],
          'label': 'Rider ${b.bookingId} · at hub GPS',
          'kind': 'rider',
        });
      }
    }
    final payload = jsonEncode({
      'lat': points.first['lat'],
      'lng': points.first['lng'],
      'points': points,
    });
    await ctrl.runJavaScript('renderMap($payload)');
  }

  Future<void> _saveReview() async {
    final item = reviewTarget ?? (rides.isNotEmpty ? rides.first : null);
    if (item == null || item.bookingId.isEmpty) {
      setState(() => note = 'No completed ride to review yet.');
      return;
    }
    final text = reviewComment.text.trim();
    if (text.isNotEmpty && text.length < 8) {
      setState(() => note = 'Write at least 8 characters, or leave the comment empty.');
      return;
    }
    setState(() => busy = true);
    try {
      final token = await _token();
      if (token == null) throw ApiException('Sign in again to save the review.');
      await EvuddyApi.submitReview(
        idToken: token,
        bookingId: item.bookingId,
        stars: reviewStars,
        comment: text,
      );
      reviewComment.clear();
      await _load();
      if (!mounted) return;
      setState(() {
        busy = false;
        note = 'Review saved on evuddy.com.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        note = e.toString();
      });
    }
  }

  Future<void> _refund() async {
    final d = registrationDraft;
    final id = d.depositBookingId ?? live?.bookingId ?? (rides.isNotEmpty ? rides.first.bookingId : '');
    if (id.isEmpty) {
      setState(() => note = 'No deposit booking is on file yet.');
      return;
    }
    setState(() => busy = true);
    try {
      final token = await _token();
      if (token == null) throw ApiException('Sign in again to open refunds.');
      final started = await EvuddyApi.requestDepositRefund(
        idToken: token,
        bookingId: id,
        bookingMongoId: live?.mongoId ?? '',
        paymentId: live?.razorpayPaymentId ?? '',
        amountRupees: d.depositHeld > 0 ? d.depositHeld : CatalogRates.securityDeposit.toDouble(),
      );
      if (!mounted) return;
      if (started.needsCheckout && started.order != null) {
        setState(() => busy = false);
        await Navigator.of(context, rootNavigator: true).push(
          evuddyRoute(
            RazorpayCheckoutPage(
              order: started.order!,
              bookingId: id,
              contact: d.phone,
              customerName: d.fullName,
              email: d.email,
              rupees: d.depositHeld > 0 ? d.depositHeld : CatalogRates.securityDeposit.toDouble(),
              bookingMongoId: live?.mongoId ?? '',
              idToken: token,
            ),
          ),
        );
        await _load();
        return;
      }
      registrationDraft.depositStatus = 'released';
      await registrationDraft.persist();
      setState(() {
        busy = false;
        note = started.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        note = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.wash,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Evuddy.ink,
        elevation: 0,
        title: Text(
          'Command center',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh live data',
            onPressed: loading ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          labelColor: Evuddy.ink,
          indicatorColor: Evuddy.rapidoYellow,
          tabs: const [
            Tab(text: 'CRM'),
            Tab(text: 'IoT GPS'),
            Tab(text: 'Refunds'),
            Tab(text: 'Reviews'),
            Tab(text: 'Team'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 2, color: Evuddy.green),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: InfoNote(text: error!),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: InfoNote(text: note!),
            ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                _crm(),
                _iot(),
                _refunds(),
                _reviews(),
                _team(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _crm() {
    final d = registrationDraft;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          d.fullName.isEmpty ? 'Rider workspace' : '${d.fullName.split(' ').first} · live ops',
          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
        ),
        const SizedBox(height: 6),
        Text(
          'Same MongoDB as evuddy.com. Numbers refresh every few seconds.',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _kpi('Cities', '${cities.length}'),
            _kpi('Hubs', '${hubs.length}'),
            _kpi('Scooters', '${vehicles.length}'),
            _kpi('Rides', '${rides.length}'),
            _kpi('Receipts', '${receipts.length}'),
            _kpi('Tickets', '${tickets.length}'),
            _kpi('Wallet', CatalogRates.inr(d.walletAvailable)),
            _kpi('Deposit', CatalogRates.inr(d.depositHeld)),
          ],
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVE FILE', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                live == null
                    ? 'No live booking. Book EV to open a new Normal or Rent to Own file.'
                    : '${live!.bookingId} · ${live!.rideStatus.isEmpty ? "Reserved" : live!.rideStatus} · remaining ${CatalogRates.inr(live!.due)}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (live?.hasPickupOtp == true) Text('Pickup OTP ${live!.pickupOtp}'),
              if (live != null && live!.rideEndOtp.isNotEmpty) Text('Ride-end OTP ${live!.rideEndOtp}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final t in tickets.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              child: Text(
                '${t.ticketId} · ${t.status} · ${t.category}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iot() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LIVE FLEET GPS', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Text(
                  live != null && live!.inRide
                      ? 'Rider file ${live!.bookingId} is in ride. Hub + scooter pins refresh from evuddy.com.'
                      : 'Hub pins use India GPS. Scooter IoT pins appear when the vehicle feed includes coordinates.',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: map == null
                  ? const ColoredBox(
                      color: Color(0xFFEEF2EF),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : WebViewWidget(controller: map!),
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              for (final v in vehicles)
                Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Evuddy.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.displayId, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                      Text(
                        v.hasGps
                            ? '${v.latitude!.toStringAsFixed(4)}, ${v.longitude!.toStringAsFixed(4)}'
                            : 'GPS via hub ${v.currentHub}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Evuddy.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _refunds() {
    final d = registrationDraft;
    final amount = d.depositHeld > 0 ? d.depositHeld : CatalogRates.securityDeposit.toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SECURITY DEPOSIT', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                CatalogRates.inr(amount),
                style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              Text(d.depositLabel, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              if (d.depositBookingId != null)
                Text('Booking ${d.depositBookingId}', style: GoogleFonts.plusJakartaSans(color: Evuddy.muted)),
              const SizedBox(height: 14),
              Text(
                'Refunds return to the original Razorpay UPI / card. If finance needs a Checkout confirmation, it opens here — the same Standard Checkout as Book EV.',
                style: GoogleFonts.plusJakartaSans(height: 1.45),
              ),
              const SizedBox(height: 14),
              EvuddyButton(
                sun: true,
                label: busy ? 'Opening Razorpay…' : 'Refund deposit via Razorpay',
                busy: busy,
                onPressed: busy ? null : _refund,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviews() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAVE REPLY', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                reviewTarget == null
                    ? (rides.isEmpty ? 'Complete a ride, then save stars and a reply.' : 'Select a ride, then save your review reply.')
                    : 'Replying on ${reviewTarget!.bookingId}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => reviewStars = i),
                      icon: Icon(
                        i <= reviewStars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                ],
              ),
              TextField(
                controller: reviewComment,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your review reply',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              EvuddyButton(
                sun: true,
                label: busy ? 'Saving…' : 'Save reply',
                busy: busy,
                onPressed: busy ? null : _saveReview,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final ride in rides)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => reviewTarget = ride),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ride.bookingId, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                          Text(
                            '${ride.rideStatus} · ${ride.rentalMode}',
                            style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
                          ),
                          if (ride.reviewStars != null) Text('Rated ${ride.reviewStars}/5'),
                        ],
                      ),
                    ),
                    Icon(
                      reviewTarget?.bookingId == ride.bookingId
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_off_rounded,
                      color: Evuddy.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _team() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Team desks',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Assigned modules load live rider and fleet data here. Empty zeros meant the desk opened without a signed-in refresh — this screen always hydrates from evuddy.com.',
          style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, height: 1.45),
        ),
        const SizedBox(height: 16),
        _desk('Fleet desk', '${vehicles.length} scooters · ${hubs.length} hubs', Icons.electric_moped_rounded),
        _desk('Yard desk', '${hubs.where((h) => h.city.isNotEmpty).length} live yards', Icons.warehouse_outlined),
        _desk('Finance desk', '${receipts.length} Razorpay receipts · deposit ${registrationDraft.depositLabel}', Icons.payments_outlined),
        _desk('Support desk', '${tickets.length} tickets', Icons.support_agent_rounded),
        _desk('Review desk', '${rides.where((r) => r.reviewStars != null).length} saved reviews', Icons.star_outline_rounded),
        const SizedBox(height: 10),
        EvuddyGhostButton(label: 'Reload assigned desks', onPressed: () => _load()),
      ],
    );
  }

  Widget _desk(String title, String body, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        child: Row(
          children: [
            Icon(icon, color: Evuddy.greenDeep),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  Text(body, style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Container(
      width: 158,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Evuddy.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20)),
        ],
      ),
    );
  }
}
