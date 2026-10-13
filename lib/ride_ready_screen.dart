import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'api/razorpay_checkout.dart';
import 'confirm_mobile_screen.dart';
import 'open_link.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class RideReadyScreen extends StatefulWidget {
  const RideReadyScreen({super.key, this.showBack = true});
  final bool showBack;

  @override
  State<RideReadyScreen> createState() => _RideReadyScreenState();
}

class _RideReadyScreenState extends State<RideReadyScreen> {
  String duration = registrationDraft.chosenDuration ?? 'Daily';
  int wizard = 2;
  List<EvuddyVehicle> vehicles = [];
  List<EvuddyHub> listedHubs = [];
  EvuddyHub? hub;
  EvuddyVehicle? selected;
  RiderBooking? booking;
  bool loading = true;
  bool busy = false;
  String? error;
  String? note;
  final amount = TextEditingController();
  final help = TextEditingController();
  String helpCategory = 'BOOKING_ISSUE';
  String? helpStatus;
  List<SupportTicket> tickets = [];
  Timer? _poll;
  Timer? _tokenKeepalive;
  String? _bookingRequestId;
  bool cityWideScooters = false;

  bool get rental {
    if (registrationDraft.chosenPlan == 'rto') return false;
    if (registrationDraft.chosenPlan == 'rental') return true;
    final mode = (booking ?? registrationDraft.activeBooking)?.rentalMode.toLowerCase() ?? '';
    if (mode.contains('own')) return false;
    return true;
  }

  String get rentalMode => rental ? duration : 'Rent To Own';

  String get durationKey => rental ? duration : 'Rent To Own';

  int get catalogFare => CatalogRates.amountForDuration(durationKey);

  int get catalogPayable => CatalogRates.payableForDuration(durationKey);

  GstSplit get gst => CatalogRates.gstInclusive(catalogFare);

  bool get remainingPay {
    final b = booking;
    if (b == null) return false;
    return b.remainingPayLocked && _remainingCharge(b) > 0.009;
  }

  double _remainingCharge(RiderBooking b) {
    if (b.due > 0.009) return b.due;
    if (!b.isRemainingPayment && b.paymentDue <= 0.009) {
      return catalogPayable.toDouble();
    }
    return 0;
  }

  double get amountDue {
    final b = booking;
    if (b == null) return catalogPayable.toDouble();
    final due = _remainingCharge(b);
    if (due > 0.009) return due;
    return catalogPayable.toDouble();
  }

  bool get walletCovers {
    final pay = remainingPay ? _remainingCharge(booking!) : (double.tryParse(amount.text.trim()) ?? amountDue);
    return !registrationDraft.walletStatus.toLowerCase().contains('block') &&
        registrationDraft.walletAvailable + 0.009 >= pay &&
        pay >= 1;
  }

  String _moneyInput(double n) {
    if ((n - n.round()).abs() < 0.009) return n.round().toString();
    return n.toStringAsFixed(2);
  }

  void _fillAmount(RiderBooking? b) {
    if (b == null) {
      amount.text = _moneyInput(catalogPayable.toDouble());
      return;
    }
    if (b.remainingPayLocked) {
      amount.text = _moneyInput(_remainingCharge(b));
    } else if (b.due > 0.009) {
      amount.text = _moneyInput(b.due);
    } else {
      amount.text = _moneyInput(catalogPayable.toDouble());
    }
  }

  @override
  void initState() {
    super.initState();
    booking = registrationDraft.activeBooking;
    if (booking != null && booking!.bookingId.isNotEmpty) wizard = 4;
    _load();
    _poll = Timer.periodic(const Duration(seconds: 7), (_) {
      final b = booking;
      if (b == null) {
        if (wizard == 2) _load(silent: true);
        return;
      }
      if (b.completed) return;
      if (b.hasPickupOtp && !b.pickupOtpVerified) _load(silent: true);
      if (b.readyForPickup && !b.inRide) _load(silent: true);
      if (b.inRide && _remainingCharge(b) > 0.009) _load(silent: true);
    });
    _tokenKeepalive = Timer.periodic(const Duration(minutes: 20), (_) {
      registrationDraft.freshToken(force: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tokenKeepalive?.cancel();
    amount.dispose();
    help.dispose();
    super.dispose();
  }

  bool _reauthOpen = false;

  Future<String?> _token({bool force = true, bool prompt = true}) async {
    final token = await registrationDraft.freshToken(force: force);
    if (token == null || token.isEmpty || EvuddyFirebase.jwtExpired(token)) {
      if (prompt) _askReauth();
      return null;
    }
    return token;
  }

  Future<T?> _withToken<T>(Future<T> Function(String token) run) async {
    var token = await _token();
    if (token == null) return null;
    try {
      return await run(token);
    } catch (e) {
      if (!registrationDraft.isAuthError(e)) rethrow;
      token = await _token(force: true, prompt: false);
      if (token == null) {
        _askReauth();
        return null;
      }
      try {
        return await run(token);
      } catch (e2) {
        if (registrationDraft.isAuthError(e2)) {
          _askReauth();
          return null;
        }
        rethrow;
      }
    }
  }

  void _askReauth() {
    if (!mounted || _reauthOpen) return;
    _reauthOpen = true;
    setState(() {
      error =
          'Firebase session expired after waiting at the yard. Confirm this same registered mobile with OTP — then pay remaining. Booking is kept.';
    });
    registrationDraft.otpGate = 'book';
    Navigator.push(context, evuddyRoute(const ConfirmMobileScreen())).then((_) {
      _reauthOpen = false;
      if (mounted) _load();
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final city = registrationDraft.chosenCity;
      var allHubs = await EvuddyApi.hubs(city: city);
      if (allHubs.isEmpty) allHubs = await EvuddyApi.hubs();
      EvuddyHub? h;
      for (final x in allHubs) {
        if (x.id == registrationDraft.chosenHubId) {
          h = x;
          break;
        }
      }
      h ??= allHubs.isEmpty ? null : allHubs.first;
      final bikes = await EvuddyApi.vehicles(
        city: city,
        hub: h?.code.isNotEmpty == true ? h!.code : h?.name,
      );
      var atHub = bikes.where((v) {
        if (h == null) return true;
        return hubMatches(v.currentHub, h);
      }).toList()
        ..sort((a, b) => b.batteryPercentage.compareTo(a.batteryPercentage));
      var wide = false;
      if (atHub.isEmpty && bikes.isNotEmpty) {
        atHub = List<EvuddyVehicle>.from(bikes)
          ..sort((a, b) => b.batteryPercentage.compareTo(a.batteryPercentage));
        wide = true;
      }

      RiderBooking? mine = booking;
      final token = await _token(force: !silent, prompt: false);
      if (token != null) {
        try {
          final latest = await EvuddyApi.myBooking(token);
          if (latest != null) {
            mine = latest;
            registrationDraft.applyActiveBooking(latest);
          } else {
            registrationDraft.applyActiveBooking(null);
            mine = null;
          }
        } catch (_) {
          if (mine != null) registrationDraft.applyActiveBooking(mine);
        }
        try {
          tickets = await EvuddyApi.myTickets(token);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        hub = h;
        listedHubs = allHubs;
        vehicles = atHub;
        cityWideScooters = wide;
        if (selected == null ||
            !atHub.any((v) => v.vehicleId == selected!.vehicleId)) {
          selected = atHub.isEmpty ? null : atHub.first;
        }
        booking = mine;
        loading = false;
        if (mine != null && mine.bookingId.isNotEmpty && !mine.completed) {
          wizard = 4;
        }
        _fillAmount(mine);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _reserve() async {
    final token = await _token();
    final bike = selected;
    final h = hub;
    final d = registrationDraft;
    if (token == null) {
      setState(() => error = 'Verify your mobile before booking.');
      return;
    }
    if (d.riderId == null || d.riderId!.isEmpty) {
      try {
        final looked = await EvuddyApi.lookupRider(phone: d.phone, idToken: token);
        if (looked.found && looked.riderId != null) {
          d.applyLookup(looked);
        }
      } catch (_) {}
    }
    if (d.riderId == null || d.riderId!.isEmpty) {
      setState(() => error = 'Rider profile is missing. Finish KYC, then retry.');
      return;
    }
    if (bike == null) {
      setState(() => error = 'No scooter is listed at this hub right now.');
      return;
    }
    if (h == null) {
      setState(() => error = 'Select a hub on Book EV first.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      note = null;
    });
    try {
      _bookingRequestId ??=
          '${DateTime.now().microsecondsSinceEpoch}-${d.phone}-${bike.vehicleId}';
      final created = await EvuddyApi.createBooking(
        idToken: token,
        userName: d.fullName.isEmpty ? 'Rider' : d.fullName,
        userPhone: d.phone,
        riderId: d.riderId!,
        vehicleId: bike.vehicleId.isNotEmpty ? bike.vehicleId : bike.id,
        hub: h,
        city: d.chosenCity ?? h.city,
        rentalMode: rentalMode,
        duration: rental ? duration : 'Rent To Own',
        referenceBy: d.comingThrough,
        bookingRequestId: _bookingRequestId,
      );
      registrationDraft
        ..chosenDuration = duration
        ..applyActiveBooking(created);
      await registrationDraft.persist();
      if (!mounted) return;
      setState(() {
        booking = created;
        busy = false;
        wizard = 4;
        note = created.message.isEmpty
            ? (rental
                ? 'Scooter reserved. Pay any amount from ₹1 on Razorpay to get pickup OTP. Remaining can be paid during the ride.'
                : 'Agreement saved. Pay today’s GST-included fare plus the ₹2,500 refundable deposit in one Razorpay payment.')
            : created.message;
        _fillAmount(created);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString();
      });
    }
  }

  double _payNow(RiderBooking b) {
    if (b.remainingPayLocked) return _remainingCharge(b);
    return double.tryParse(amount.text.trim()) ?? 0;
  }

  Future<void> _pay({bool useWallet = false}) async {
    if (booking == null) {
      setState(() => error = 'Reserve a scooter first.');
      return;
    }
    var b = booking!;
    var token = await _token();
    if (token == null) return;
    if (b.mongoId.isEmpty) {
      try {
        final mine = await EvuddyApi.myBooking(token);
        if (mine != null) {
          b = mine;
          registrationDraft.applyActiveBooking(mine);
          if (mounted) setState(() => booking = mine);
        }
      } catch (e) {
        if (registrationDraft.isAuthError(e)) {
          _askReauth();
          return;
        }
      }
    }
    if (b.mongoId.isEmpty) {
      setState(() => error = 'Booking id is missing. Refresh, then pay.');
      return;
    }
    final maxDue = amountDue;
    final pay = _payNow(b);
    if (b.remainingPayLocked) {
      amount.text = _moneyInput(pay);
    }
    if (pay < 1 || pay > maxDue + 0.009) {
      setState(() => error = b.isRentToOwn
          ? 'Rent to Own needs today’s full GST-included amount plus deposit in one payment.'
          : 'Enter a payment between ₹1 and ${CatalogRates.inr(maxDue)}.');
      return;
    }
    if (useWallet && registrationDraft.walletAvailable + 0.009 < pay) {
      setState(() => error =
          'Wallet has ${CatalogRates.inr(registrationDraft.walletAvailable)}. Pay with Razorpay.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final started = await _withToken(
        (t) => EvuddyApi.startPayment(
          idToken: t,
          bookingMongoId: b.mongoId,
          amountRupees: pay,
          useWallet: useWallet,
        ),
      );
      if (started == null) {
        if (mounted) setState(() => busy = false);
        return;
      }
      token = registrationDraft.firebaseIdToken ?? token;
      if (!mounted) return;
      Map<String, String>? result;
      if (started.needsCheckout) {
        setState(() => busy = false);
        result = await Navigator.push<Map<String, String>>(
          context,
          evuddyRoute(
            RazorpayCheckoutPage(
              order: started.order!,
              bookingId: b.bookingId,
              contact: registrationDraft.phone,
              customerName: registrationDraft.fullName,
              email: registrationDraft.email,
              rupees: pay,
              vehicleId: selected?.vehicleId ?? b.vehicleId,
            ),
          ),
        );
        if (result == null) return;
        setState(() => busy = true);
      }
      RiderBooking verified;
      if (started.booking != null && result == null) {
        verified = started.booking!;
      } else {
        final paid = await _withToken(
          (t) => EvuddyApi.verifyPayment(
            idToken: t,
            bookingMongoId: b.mongoId,
            orderId: result?['orderId'],
            paymentId: result?['paymentId'],
            signature: result?['signature'],
          ),
        );
        if (paid == null) {
          if (mounted) setState(() => busy = false);
          return;
        }
        verified = paid;
      }
      token = registrationDraft.firebaseIdToken ?? token;
      final mine = await EvuddyApi.myBooking(token);
      if (mine != null) verified = verified.mergedWith(mine);
      registrationDraft.applyActiveBooking(verified);
      if (pay >= 1) {
        final held = verified.securityDeposit > 0
            ? verified.securityDeposit
            : CatalogRates.securityDeposit.toDouble();
        registrationDraft
          ..depositHeld = held
          ..depositStatus = 'held'
          ..depositBookingId = verified.bookingId.isEmpty ? b.bookingId : verified.bookingId;
      }
      if (useWallet) {
        registrationDraft.walletAvailable =
            (registrationDraft.walletAvailable - pay).clamp(0, 1e12).toDouble();
      }
      if (verified.hasPickupOtp) {
        try {
          await EvuddyApi.notifyPickupOtp(
            idToken: token,
            bookingId: verified.bookingId.isEmpty ? b.bookingId : verified.bookingId,
          );
        } catch (_) {}
      }
      var noteText = verified.message;
      if (noteText.isEmpty) {
        if (verified.due > 0.009 && verified.hasPickupOtp) {
          noteText =
              'Pickup OTP ${verified.pickupOtp}. Tell this to the yard. Remaining ${CatalogRates.inr(verified.due)} must be paid before ride-end OTP.';
        } else if (verified.hasPickupOtp) {
          noteText = 'Payment successful. Pickup OTP ${verified.pickupOtp}. Show this at the hub.';
        } else if (verified.due <= 0.009) {
          noteText =
              'Remaining is ₹0. Start the ride at the yard, then generate ride-end OTP — same as evuddy.com.';
        } else {
          noteText = useWallet ? 'Wallet payment saved.' : 'Payment saved.';
        }
      }
      if (!mounted) return;
      setState(() {
        booking = verified;
        busy = false;
        note = noteText;
        _fillAmount(verified);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      if (registrationDraft.isAuthError(e)) {
        _askReauth();
        return;
      }
      setState(() => error = e.toString());
    }
  }

  Future<void> _resendOtp() async {
    final token = await _token();
    final id = booking?.bookingId;
    if (token == null || id == null || id.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await EvuddyApi.notifyPickupOtp(idToken: token, bookingId: id);
      if (!mounted) return;
      setState(() {
        busy = false;
        note = 'OTP SMS requested from evuddy.com.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString();
      });
    }
  }

  Future<void> _ride(bool start) async {
    final current = booking;
    if (start && current != null && !current.pickupOtpVerified) {
      setState(() => error = 'Wait for the yard to enter pickup OTP first — same as evuddy.com.');
      return;
    }
    if (!start && current != null && current.isRentToOwn) {
      setState(() => error = 'Rent to Own has no ride-end OTP. The scooter stays with you.');
      return;
    }
    if (!start && current != null && !current.inRide) {
      setState(() => error = 'Start the ride after yard pickup OTP, then generate ride-end OTP.');
      return;
    }
    if (!start && current != null && _remainingCharge(current) > 0.009) {
      setState(() => error =
          'Pay remaining ${CatalogRates.inr(_remainingCharge(current))} on Razorpay before ride-end OTP.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ended = await _withToken(
        (token) => EvuddyApi.rideAction(
          idToken: token,
          start: start,
          bookingId: booking?.bookingId,
        ),
      );
      if (ended == null) {
        if (mounted) setState(() => busy = false);
        return;
      }
      RiderBooking? mine = booking;
      try {
        final token = registrationDraft.firebaseIdToken;
        if (token != null) mine = await EvuddyApi.myBooking(token) ?? booking;
      } catch (_) {}
      if (mine != null) {
        mine = mine.copy(
          rideEndOtp: ended.rideEndOtp.isNotEmpty ? ended.rideEndOtp : null,
          rideStatus: ended.rideStatus.isNotEmpty ? ended.rideStatus : null,
          message: ended.message,
        );
        registrationDraft.applyActiveBooking(mine);
      }
      if (!start &&
          registrationDraft.depositHeld > 0 &&
          registrationDraft.depositStatus == 'held') {
        registrationDraft.depositStatus = 'refund_pending';
      }
      if (!mounted) return;
      setState(() {
        booking = mine ?? booking;
        busy = false;
        note = ended.message;
        _fillAmount(mine ?? booking);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      if (registrationDraft.isAuthError(e)) {
        _askReauth();
        return;
      }
      setState(() => error = e.toString());
    }
  }

  Future<void> _sendHelp() async {
    final text = help.text.trim();
    if (text.length < 10) {
      setState(() => helpStatus = 'Describe the issue in at least 10 characters.');
      return;
    }
    final token = await _token();
    final id = booking?.bookingId;
    if (token == null || id == null || id.isEmpty) {
      setState(() => helpStatus = 'Sign in and complete booking first.');
      return;
    }
    setState(() {
      busy = true;
      helpStatus = null;
    });
    try {
      await EvuddyApi.createTicket(
        idToken: token,
        bookingId: id,
        userId: registrationDraft.phone.isNotEmpty
            ? registrationDraft.phone
            : (registrationDraft.riderId ?? 'rider'),
        category: helpCategory,
        description: () {
          final desc = '${booking?.inRide == true ? 'During ride: ' : ''}$text';
          return desc.length > 500 ? desc.substring(0, 500) : desc;
        }(),
      );
      help.clear();
      tickets = await EvuddyApi.myTickets(token);
      if (!mounted) return;
      setState(() {
        busy = false;
        helpStatus = 'Support ticket sent. Hub staff see it on Support.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        helpStatus = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final b = booking;
    final step = b != null && b.bookingId.isNotEmpty
        ? 4
        : wizard;
    return AuthScreen(
      showBack: widget.showBack,
      compact: b != null && b.bookingId.isNotEmpty,
      step: b != null && b.bookingId.isNotEmpty ? null : step,
      of: 4,
      kicker: b != null && b.bookingId.isNotEmpty
          ? (b.bookingId.isEmpty ? 'BOOKING' : b.bookingId)
          : (wizard == 3 ? 'BOOKING REVIEW' : (rental ? 'CHOOSE SCOOTER' : 'RENT TO OWN')),
      title: b != null && b.bookingId.isNotEmpty
          ? (b.completed
              ? 'Ride complete'
              : remainingPay
                  ? 'Pay remaining'
                  : (b.due <= 0.009 && b.hasPickupOtp
                      ? "You're booked"
                      : 'Pay to confirm'))
          : (wizard == 3
              ? 'Review your booking'
              : (rental ? 'Pick duration and scooter' : '${CatalogRates.rtoMonths}-month ownership')),
      subtitle: b != null && b.bookingId.isNotEmpty
          ? (b.pickupOtpVerified
              ? 'Yard confirmed pickup. Slide to start, then pay any remaining on Razorpay.'
              : (remainingPay
                  ? 'Razorpay UPI or card. Same booking as evuddy.com.'
                  : 'Pay from ₹1 for pickup OTP. Remaining can wait until return.'))
          : (wizard == 3
              ? 'GST included fare + refundable deposit. Then Razorpay — same as evuddy.com.'
              : (rental
                  ? 'Hourly ₹60 · Daily ₹250 GST included. Deposit ₹2,500 held until return.'
                  : '${CatalogRates.inr(CatalogRates.rtoDaily)}/day · ${CatalogRates.rtoMonths} months · ${CatalogRates.inr(CatalogRates.securityDeposit)} hold.')),
      error: error,
      footer: _footer(b),
      children: [
        if (loading) const InfoNote(text: 'Loading live scooters…'),
        if (hub != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hub!.name} · ${hub!.location}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hub!.city} · ${rental ? duration : "Rent to Own"}',
                  style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                EvuddyGhostButton(
                  label: 'Open hub in Maps',
                  onPressed: () => launchMaps(hub!.mapsQuery),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (b == null && wizard == 2) ...[
          if (rental)
            ChoicePills(
              options: const ['Hourly', 'Daily', 'Weekly', 'Monthly'],
              value: duration,
              onChanged: (v) => setState(() {
                duration = v;
                _fillAmount(null);
              }),
            ),
          if (rental) const SizedBox(height: 16),
          Text('LIVE SCOOTERS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          if (!loading && vehicles.isEmpty)
            const InfoNote(
              text:
                  'No scooters are marked Available on evuddy.com right now. Pull to refresh, or ask the yard to set bikes to Available — then they appear here instantly.',
            ),
          if (cityWideScooters && vehicles.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: InfoNote(
                text:
                    'Showing every Available scooter in this city. Tap one to book it at its hub — same catalog as evuddy.com/book-bike.',
              ),
            ),
          for (final v in vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ScooterPickCard(
                vehicle: v,
                selected: selected?.vehicleId == v.vehicleId,
                fareLabel: '${CatalogRates.inr(catalogFare)} GST included',
                onTap: () => setState(() {
                  selected = v;
                  for (final x in listedHubs) {
                    if (hubMatches(v.currentHub, x)) {
                      hub = x;
                      registrationDraft
                        ..chosenHubId = x.id
                        ..chosenCity = x.city.isNotEmpty ? x.city : registrationDraft.chosenCity
                        ..persist();
                      break;
                    }
                  }
                }),
              ),
            ),
        ],
        if (b == null && wizard == 3) _reviewCard(d),
        if (b != null) ..._bookingCards(b),
        if (note != null) ...[
          const SizedBox(height: 12),
          InfoNote(text: note!),
        ],
      ],
    );
  }

  Widget _reviewCard(RegistrationDraft d) {
    return Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PAYABLE', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                CatalogRates.inr(catalogPayable),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Evuddy.greenDeep,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'GST included in the fare. ₹2,500 refundable deposit is added — same as evuddy.com.',
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            children: [
              _ReviewRow('Rider', d.fullName.isEmpty ? 'Rider' : d.fullName),
              _ReviewRow('Rider ID', d.riderId ?? '—'),
              _ReviewRow('Vehicle', selected?.vehicleId ?? selected?.registrationNumber ?? '—'),
              _ReviewRow('Model', selected?.vehicleModel ?? '—'),
              _ReviewRow('City', hub?.city ?? d.chosenCity ?? '—'),
              _ReviewRow('Hub', hub == null ? '—' : '${hub!.name} (${hub!.code})'),
              _ReviewRow('Mode', rentalMode),
              _ReviewRow('Fare (GST included)', CatalogRates.inr(catalogFare)),
              _ReviewRow('Taxable', CatalogRates.inr(gst.taxable)),
              _ReviewRow('CGST 2.5% + SGST 2.5%', CatalogRates.inr(gst.gst)),
              _ReviewRow('Security deposit', CatalogRates.inr(CatalogRates.securityDeposit)),
              _ReviewRow('Total', CatalogRates.inr(catalogPayable)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _bookingCards(RiderBooking b) {
    return [
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid ${CatalogRates.inr(b.receivedAmount)}  ·  remaining ${CatalogRates.inr(_remainingCharge(b))}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '${b.paymentStatus.isEmpty ? "Pending" : b.paymentStatus} · ${b.rideStatus.isEmpty ? "Reserved" : b.rideStatus}',
              style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontWeight: FontWeight.w600),
            ),
            if (b.vehicleNumber.isNotEmpty) Text(b.vehicleNumber),
            const SizedBox(height: 8),
            Text(
              'Wallet ${CatalogRates.inr(registrationDraft.walletAvailable)} · Razorpay UPI / card (no PhonePe app)',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Evuddy.muted),
            ),
          ],
        ),
      ),
      if (b.hasPickupOtp && !b.pickupOtpVerified) ...[
        const SizedBox(height: 12),
        OtpReveal(
          label: 'PICKUP OTP',
          code: b.pickupOtp,
          hint: 'Show this at the hub. The yard enters it — same as evuddy.com.',
        ),
      ],
      if (b.pickupOtpVerified && !b.inRide && !b.completed) ...[
        const SizedBox(height: 12),
        const InfoNote(
          text: 'Yard accepted pickup OTP. Slide to start your ride — same as the website.',
        ),
      ],
      if (b.completed) ...[
        const SizedBox(height: 12),
        const InfoNote(
          text:
              'Thank you for riding with EVUDDY. Deposit refunds (if any) are approved by admin after return.',
        ),
      ],
      if (b.rideEndOtp.isNotEmpty) ...[
        const SizedBox(height: 12),
        OtpReveal(
          label: 'RIDE END OTP',
          code: b.rideEndOtp,
          hint: 'Tell this to the yard to return the scooter.',
        ),
      ],
      if (b.inRide && b.due > 0.009) ...[
        const SizedBox(height: 12),
        InfoNote(
          text: b.isRentToOwn
              ? 'Today’s Rent to Own ${CatalogRates.inr(b.due)} (GST included) is due. Pay here. Keep the scooter — no ride-end OTP.'
              : 'Remaining ${CatalogRates.inr(b.due)} must be paid on Razorpay before you can slide to end the ride.',
        ),
      ],
      if (b.due > 0.009 || remainingPay) ...[
        const SizedBox(height: 16),
        if (remainingPay)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REMAINING DUE', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(
                  CatalogRates.inr(_remainingCharge(b)),
                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  b.isRentToOwn
                      ? 'Rent to Own must be paid in full. Razorpay UPI or card — same as the website.'
                      : 'Loaded from this booking. Razorpay will charge only the remaining due.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Evuddy.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              labelText: 'Pay amount (₹1 to remaining)',
              filled: true,
              fillColor: Evuddy.paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
      ],
      if (b.receivedAmount >= 1 && !b.completed) ...[
        const SizedBox(height: 18),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help with this booking?',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock, breakdown, battery or payment. Hub staff see it immediately.',
                style: GoogleFonts.plusJakartaSans(color: Evuddy.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: helpCategory,
                items: const [
                  DropdownMenuItem(value: 'BOOKING_ISSUE', child: Text('Booking / general')),
                  DropdownMenuItem(value: 'UNLOCK_ISSUE', child: Text('Unlock / pickup OTP')),
                  DropdownMenuItem(value: 'VEHICLE_BREAKDOWN', child: Text('Scooter breakdown')),
                  DropdownMenuItem(value: 'BATTERY_ISSUE', child: Text('Battery / range')),
                  DropdownMenuItem(value: 'PAYMENT_ISSUE', child: Text('Payment')),
                  DropdownMenuItem(value: 'REFUND_REQUEST', child: Text('Deposit refund')),
                ],
                onChanged: (v) => setState(() => helpCategory = v ?? 'BOOKING_ISSUE'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: help,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What happened? Example: scooter stopped, battery died…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              EvuddyGhostButton(label: 'Send to support', onPressed: busy ? null : _sendHelp),
              if (helpStatus != null) ...[
                const SizedBox(height: 8),
                Text(helpStatus!, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              ],
              for (final t in tickets.take(5))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${t.ticketId} · ${t.status} · ${t.category}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Evuddy.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _footer(RiderBooking? b) {
    if (busy) {
      return const EvuddyButton(label: 'Working…', onPressed: null, busy: true);
    }
    if (b == null) {
      if (wizard == 3) {
        return Column(
          children: [
            EvuddyButton(label: 'Reserve scooter', onPressed: _reserve),
            const SizedBox(height: 8),
            EvuddyGhostButton(label: 'Back', onPressed: () => setState(() => wizard = 2)),
          ],
        );
      }
      if (vehicles.isEmpty) {
        return EvuddyButton(
          label: 'Refresh scooters',
          icon: Icons.refresh_rounded,
          onPressed: _load,
        );
      }
      return EvuddyButton(
        label: 'Continue to review',
        onPressed: () {
          selected ??= vehicles.first;
          setState(() => wizard = 3);
        },
      );
    }
    if (b.completed) {
      return EvuddyButton(label: 'Refresh booking', onPressed: _load);
    }
    final payDue = b.due > 0.009 || remainingPay;
    final waitForStart = b.pickupOtpVerified && !b.inRide;
    return Column(
      children: [
        if (waitForStart) ...[
          RideSwipeBar(
            label: 'Slide to start ride',
            hint: 'Yard has saved your pickup OTP. Slide to start — then pay remaining on Razorpay.',
            busy: busy,
            onConfirm: () => _ride(true),
          ),
          if (payDue) ...[
            const SizedBox(height: 10),
            Text(
              'Remaining ${CatalogRates.inr(_remainingCharge(b))} is paid after this slide — same as evuddy.com.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Evuddy.muted, height: 1.35),
            ),
          ],
        ] else if (b.hasPickupOtp && !b.pickupOtpVerified) ...[
          const SizedBox(height: 8),
          EvuddyGhostButton(label: 'Resend pickup OTP SMS', onPressed: _resendOtp),
          const SizedBox(height: 8),
          EvuddyGhostButton(label: 'Refresh after yard confirms OTP', onPressed: _load),
        ],
        if (payDue && !waitForStart) ...[
          EvuddyButton(
            label: remainingPay
                ? 'Pay remaining ${CatalogRates.inr(_remainingCharge(b))} with Razorpay'
                : 'Pay securely with Razorpay',
            onPressed: () => _pay(),
          ),
          const SizedBox(height: 8),
          EvuddyGhostButton(
            label: registrationDraft.walletAvailable < 1
                ? 'Wallet ₹0 — use Razorpay'
                : walletCovers
                    ? 'Pay ${CatalogRates.inr(_payNow(b))} from wallet'
                    : 'Wallet ${CatalogRates.inr(registrationDraft.walletAvailable)} — not enough',
            onPressed: walletCovers ? () => _pay(useWallet: true) : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Wallet is EVUDDY credit (returned deposits and admin top-ups), not UPI. Razorpay is the online path — same as the website. No PhonePe.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Evuddy.muted, height: 1.35),
          ),
        ],
        if (b.inRide && b.due <= 0.009 && b.rideEndOtp.isEmpty && !b.isRentToOwn) ...[
          const SizedBox(height: 12),
          RideSwipeBar(
            label: 'Slide to end ride',
            hint: 'Remaining is ₹0. You are at the yard. Slide to generate ride-end OTP.',
            busy: busy,
            onConfirm: () => _ride(false),
          ),
        ],
        if (b.inRide && b.isRentToOwn && b.due <= 0.009) ...[
          const SizedBox(height: 8),
          const InfoNote(
            text:
                'Today’s Rent to Own day is paid. Keep the scooter. No ride-end OTP.',
          ),
        ],
        if (!payDue && !b.hasPickupOtp && !b.readyForPickup && !b.inRide) ...[
          const SizedBox(height: 8),
          EvuddyButton(label: 'Refresh booking', onPressed: _load),
        ],
      ],
    );
  }
}

class ScooterPickCard extends StatelessWidget {
  const ScooterPickCard({
    super.key,
    required this.vehicle,
    required this.selected,
    required this.fareLabel,
    required this.onTap,
  });

  final EvuddyVehicle vehicle;
  final bool selected;
  final String fareLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = vehicle.batteryPercentage.clamp(0, 100) / 100;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Evuddy.green : Evuddy.line,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: Evuddy.lift,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: const Color(0xFFFFF8DC),
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          Evuddy.yellowScooterAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.displayId,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_off_rounded,
                            color: selected ? Evuddy.green : Evuddy.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          vehicle.vehicleModel,
                          if (vehicle.registrationNumber.isNotEmpty)
                            vehicle.registrationNumber,
                          if (vehicle.currentHub.isNotEmpty) 'Hub ${vehicle.currentHub}',
                        ].join(' · '),
                        style: GoogleFonts.plusJakartaSans(
                          color: Evuddy.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Evuddy.line,
                          color: pct > 0.4 ? Evuddy.green : Evuddy.magenta,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Battery ${vehicle.batteryPercentage.round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: Evuddy.greenDeep,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            fareLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Evuddy.greenDeep,
                            ),
                          ),
                        ],
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Evuddy.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
