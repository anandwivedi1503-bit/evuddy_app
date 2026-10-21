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
import 'widgets/booking_ui.dart';
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
  late final TextEditingController rtoNominee;
  late final TextEditingController rtoGuardian;
  late final TextEditingController rtoEmergency;
  late final TextEditingController rtoAddress;
  late final TextEditingController rtoOccupation;
  String rtoRelation = registrationDraft.rtoNomineeRelation;
  bool rtoAgreed = registrationDraft.rtoAgreed;
  String helpCategory = 'BOOKING_ISSUE';
  int reviewStars = 5;
  final reviewComment = TextEditingController();
  String? reviewStatus;
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
      amount.text = '1';
      return;
    }
    if (b.remainingPayLocked) {
      amount.text = _moneyInput(_remainingCharge(b));
      return;
    }
    amount.text = '1';
  }

  @override
  void initState() {
    super.initState();
    booking = registrationDraft.activeBooking;
    final d = registrationDraft;
    rtoNominee = TextEditingController(text: d.rtoNomineeName);
    rtoGuardian = TextEditingController(text: d.rtoGuardianName);
    rtoEmergency = TextEditingController(text: d.rtoEmergencyPhone);
    rtoAddress = TextEditingController(text: d.rtoAddress);
    rtoOccupation = TextEditingController(text: d.rtoOccupation);
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
    reviewComment.dispose();
    rtoNominee.dispose();
    rtoGuardian.dispose();
    rtoEmergency.dispose();
    rtoAddress.dispose();
    rtoOccupation.dispose();
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
    Navigator.of(context, rootNavigator: true)
        .push(evuddyRoute(const ConfirmMobileScreen()))
        .then((_) {
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

  void _saveRtoDraft() {
    registrationDraft
      ..rtoNomineeName = rtoNominee.text.trim()
      ..rtoNomineeRelation = rtoRelation
      ..rtoGuardianName = rtoGuardian.text.trim()
      ..rtoEmergencyPhone = rtoEmergency.text.replaceAll(RegExp(r'\D'), '')
      ..rtoAddress = rtoAddress.text.trim()
      ..rtoOccupation = rtoOccupation.text.trim()
      ..rtoAgreed = rtoAgreed
      ..persist();
  }

  Future<void> _submitReview() async {
    final id = booking?.bookingId;
    if (id == null || id.isEmpty) return;
    final comment = reviewComment.text.trim();
    if (comment.isNotEmpty && comment.length < 8) {
      setState(() => reviewStatus = 'Write at least 8 characters, or leave the comment empty.');
      return;
    }
    setState(() {
      busy = true;
      reviewStatus = null;
    });
    try {
      await _withToken(
        (token) => EvuddyApi.submitReview(
          idToken: token,
          bookingId: id,
          stars: reviewStars,
          comment: comment,
        ),
      );
      if (!mounted) return;
      setState(() {
        busy = false;
        reviewStatus = 'Review saved on evuddy.com. Thank you.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        reviewStatus = e.toString();
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
    RtoAgreement? rto;
    if (!rental) {
      _saveRtoDraft();
      rto = registrationDraft.rtoAgreement;
      final rtoError = rto.validationError;
      if (rtoError != null) {
        setState(() => error = rtoError);
        return;
      }
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
        rto: rto,
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
    var token = await _token(force: true);
    if (token == null) return;
    try {
      final latest = await EvuddyApi.myBooking(token);
      if (latest != null) {
        b = latest;
        registrationDraft.applyActiveBooking(latest);
        if (mounted) setState(() => booking = latest);
      }
    } catch (e) {
      if (registrationDraft.isAuthError(e)) {
        _askReauth();
        return;
      }
    }
    if (b.mongoId.isEmpty) {
      setState(() => error = 'Booking id is missing. Refresh, then pay.');
      return;
    }
    final maxDue = _remainingCharge(b) > 0.009
        ? _remainingCharge(b)
        : catalogPayable.toDouble();
    final pay = b.remainingPayLocked ? _remainingCharge(b) : _payNow(b);
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
      note = useWallet ? 'Applying wallet…' : 'Creating Razorpay order...';
    });
    try {
      var started = await _withToken(
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
      final attached = started.booking;
      // After the captured ₹1, create-order mints a new remaining order. If
      // this call only attached that first rupee, ask once more like a second
      // Pay remaining tap on evuddy.com.
      if (!useWallet &&
          !started.needsCheckout &&
          attached != null &&
          attached.due > 0.009) {
        final again = await _withToken(
          (t) => EvuddyApi.startPayment(
            idToken: t,
            bookingMongoId: b.mongoId,
            amountRupees: pay,
          ),
        );
        if (again != null && again.needsCheckout) {
          started = again;
        }
      }
      if (!mounted) return;
      Map<String, String>? result;
      RiderBooking? recovered;
      if (!useWallet && started.needsCheckout && started.order != null) {
        setState(() => busy = false);
        if (!mounted) return;
        result = await Navigator.of(context, rootNavigator: true).push<Map<String, String>>(
          evuddyRoute(
            RazorpayCheckoutPage(
              order: started.order!,
              bookingId: b.bookingId,
              contact: registrationDraft.phone,
              customerName: registrationDraft.fullName,
              email: registrationDraft.email,
              rupees: pay,
              vehicleId: selected?.vehicleId ?? b.vehicleId,
              bookingMongoId: b.mongoId,
              idToken: token,
            ),
          ),
        );
        if (result != null && result['cancelled'] == 'true') {
          if (!mounted) return;
          if (attached != null && attached.hasPickupOtp) {
            registrationDraft.applyActiveBooking(attached);
            setState(() {
              booking = attached;
              busy = false;
              error =
                  'Payment cancelled. Pickup OTP is still ${attached.pickupOtp}. Tap Pay remaining to open Razorpay again.';
              note =
                  'Pickup OTP ${attached.pickupOtp}. Tell this to the yard. Remaining ${CatalogRates.inr(attached.due)} must be paid before ride-end OTP.';
              _fillAmount(attached);
            });
            return;
          }
          setState(() {
            busy = false;
            error =
                'Payment cancelled. Tap Pay securely with Razorpay again to open GPay / PhonePe / UPI.';
          });
          return;
        }
        if (result != null && result['alreadyPaid'] == 'true') {
          try {
            recovered = await EvuddyApi.myBooking(token);
          } catch (_) {
            recovered = started.booking;
          }
          result = null;
        } else if (result == null || (result['paymentId'] ?? '').isEmpty) {
          try {
            recovered = await EvuddyApi.verifyPayment(
              idToken: token,
              bookingMongoId: b.mongoId,
              recover: true,
            );
            if (!(recovered.hasPickupOtp || recovered.receivedAmount + 0.009 >= pay)) {
              recovered = null;
            }
          } catch (_) {
            recovered = null;
          }
          if (recovered == null && (result == null || (result['paymentId'] ?? '').isEmpty)) {
            if (!mounted) return;
            const closed =
                'Razorpay closed without a payment. Tap Pay securely with Razorpay again and choose GPay, PhonePe, UPI or card.';
            setState(() {
              busy = false;
              error = closed;
            });
            await _payAlert('Payment not completed', closed);
            return;
          }
        }
        setState(() => busy = true);
      }
      RiderBooking verified;
      if (recovered != null) {
        verified = recovered;
      } else if (useWallet ||
          ((started.booking ?? attached) != null &&
              result == null &&
              (started.booking ?? attached)!.due <= 0.009)) {
        verified = (started.booking ?? attached)!;
      } else if ((started.booking ?? attached) != null &&
          result == null &&
          !started.needsCheckout) {
        final leftover = started.booking ?? attached;
        if (!mounted) return;
        setState(() {
          booking = leftover;
          busy = false;
          error = 'Could not open Razorpay. Please try again.';
          note = leftover != null && leftover.hasPickupOtp
              ? 'Pickup OTP ${leftover.pickupOtp}. Remaining ${CatalogRates.inr(leftover.due)} — tap Pay remaining.'
              : null;
          if (leftover != null) _fillAmount(leftover);
        });
        await _payAlert('Razorpay did not open', 'Could not open Razorpay. Please try again.');
        return;
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
      if (verified.due > 0.009 &&
          (noteText.toLowerCase().contains('already verified') ||
              noteText.toLowerCase().contains('already captured'))) {
        noteText =
            '₹${verified.receivedAmount.round()} is saved on this booking. Remaining ${CatalogRates.inr(verified.due)} — tap Pay remaining for Razorpay.';
      }
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
      final text = e.toString().replaceFirst('ApiException: ', '');
      setState(() => error = text);
      await _payAlert('Razorpay did not open', text);
    }
  }

  Future<void> _payAlert(String title, String body) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    return BookStage(
      showBack: widget.showBack,
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
            DurationRail(
              value: duration,
              onChanged: (v) => setState(() {
                duration = v;
                _fillAmount(null);
              }),
            ),
          if (rental) const SizedBox(height: 16),
          const SectionLabel('Live scooters'),
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
        if (!rental) ...[
          const SizedBox(height: 12),
          FormDeck(
            eyebrow: 'Ownership',
            title: 'Rent to Own agreement',
            icon: Icons.assignment_ind_outlined,
            children: [
              EvuddyField(
                label: 'NOMINEE NAME *',
                hint: 'As on Aadhaar',
                controller: rtoNominee,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              const SectionLabel('Nominee relation'),
              const SizedBox(height: 8),
              ChoicePills(
                options: RtoAgreement.relations,
                value: rtoRelation,
                onChanged: (v) => setState(() => rtoRelation = v),
              ),
              const SizedBox(height: 12),
              EvuddyField(
                label: 'FATHER / GUARDIAN *',
                hint: 'Required by the yard',
                controller: rtoGuardian,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              EvuddyField(
                label: 'EMERGENCY MOBILE *',
                hint: '10-digit number',
                controller: rtoEmergency,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: const PhonePrefix(),
              ),
              const SizedBox(height: 12),
              EvuddyField(
                label: 'OCCUPATION *',
                hint: 'Work or student',
                controller: rtoOccupation,
              ),
              const SizedBox(height: 12),
              EvuddyField(
                label: 'PERMANENT ADDRESS *',
                hint: 'House, street, city — at least 12 characters',
                controller: rtoAddress,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: rtoAgreed,
                onChanged: (v) => setState(() {
                  rtoAgreed = v;
                  _saveRtoDraft();
                }),
                title: Text(
                  'I accept the ${CatalogRates.rtoMonths}-month Rent to Own ownership agreement, same as evuddy.com.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _bookingCards(RiderBooking b) {
    final due = _remainingCharge(b);
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF052E16), Color(0xFF16A34A)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              due > 0.009 ? 'AMOUNT DUE' : 'PAID',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CatalogRates.inr(due > 0.009 ? due : b.receivedAmount),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
                height: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${b.bookingId} · ${b.rideStatus.isEmpty ? "Reserved" : b.rideStatus}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paid ${CatalogRates.inr(b.receivedAmount)} · Razorpay UPI / card',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
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
              'Thank you for riding with EVUDDY. Deposit refunds (if any) are approved by admin after return. Rate this ride so the same review shows on evuddy.com.',
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RATE THIS RIDE', style: Theme.of(context).textTheme.labelSmall),
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
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Optional comment (8+ characters if you write one)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              EvuddyGhostButton(label: 'Save review on evuddy.com', onPressed: busy ? null : _submitReview),
              if (reviewStatus != null) ...[
                const SizedBox(height: 8),
                Text(reviewStatus!, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              ],
            ],
          ),
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
          EvuddyField(
            label: 'PAY AMOUNT',
            hint: 'Starts at ₹1 for pickup OTP — same as evuddy.com',
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
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
                  DropdownMenuItem(value: 'OVERCHARGING', child: Text('Overcharging')),
                  DropdownMenuItem(value: 'REFUND_REQUEST', child: Text('Deposit refund')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
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
      return const EvuddyButton(sun: true, label: 'Working…', onPressed: null, busy: true);
    }
    if (b == null) {
      if (wizard == 3) {
        return Column(
          children: [
            EvuddyButton(
              sun: true,
              label: 'Reserve scooter',
              onPressed: () {
                if (!rental) _saveRtoDraft();
                _reserve();
              },
            ),
            const SizedBox(height: 8),
            EvuddyGhostButton(label: 'Back', onPressed: () => setState(() => wizard = 2)),
          ],
        );
      }
      if (vehicles.isEmpty) {
        return EvuddyButton(
          sun: true,
          label: 'Refresh scooters',
          icon: Icons.refresh_rounded,
          onPressed: _load,
        );
      }
      return EvuddyButton(
        sun: true,
        label: 'Continue to review',
        onPressed: () {
          selected ??= vehicles.first;
          setState(() => wizard = 3);
        },
      );
    }
    if (b.completed) {
      return EvuddyButton(sun: true, label: 'Refresh booking', onPressed: _load);
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
          const SizedBox(height: 10),
        ] else if (b.hasPickupOtp && !b.pickupOtpVerified) ...[
          const SizedBox(height: 8),
          EvuddyGhostButton(label: 'Resend pickup OTP SMS', onPressed: _resendOtp),
          const SizedBox(height: 8),
          EvuddyGhostButton(label: 'Refresh after yard confirms OTP', onPressed: _load),
        ],
        if (error != null && error!.isNotEmpty) ...[
          InfoNote(text: error!),
          const SizedBox(height: 8),
        ],
        if (payDue) ...[
          EvuddyButton(
            sun: true,
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
          EvuddyButton(sun: true, label: 'Refresh booking', onPressed: _load),
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
            color: selected ? const Color(0xFFFFF4C2) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Evuddy.ink : Evuddy.line,
              width: selected ? 2 : 1,
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
                    color: selected ? Evuddy.rapidoYellow : const Color(0xFFFFF8DC),
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
                            color: Evuddy.ink,
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
                          color: pct > 0.4 ? Evuddy.ink : Evuddy.magenta,
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
