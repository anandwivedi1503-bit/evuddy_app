import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/evuddy_api.dart';
import 'api/razorpay_checkout.dart';
import 'open_link.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

class RideReadyScreen extends StatefulWidget {
  const RideReadyScreen({super.key});

  @override
  State<RideReadyScreen> createState() => _RideReadyScreenState();
}

class _RideReadyScreenState extends State<RideReadyScreen> {
  String duration = registrationDraft.chosenDuration == 'Hourly'
      ? 'Daily'
      : (registrationDraft.chosenDuration ?? 'Daily');
  List<EvuddyVehicle> vehicles = [];
  EvuddyHub? hub;
  EvuddyVehicle? selected;
  RiderBooking? booking;
  bool loading = true;
  bool busy = false;
  String? error;
  String? note;
  final amount = TextEditingController();

  bool get rental => registrationDraft.chosenPlan != 'rto';

  bool get needsDepositHold {
    if (rental) return false;
    return registrationDraft.depositHeld + 0.009 < CatalogRates.securityDeposit;
  }

  String get rentalMode =>
      rental ? duration : 'Rent To Own';

  @override
  void initState() {
    super.initState();
    booking = registrationDraft.activeBooking;
    _load();
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    var token = registrationDraft.firebaseIdToken;
    if (token != null && token.isNotEmpty) return token;
    return null;
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final city = registrationDraft.chosenCity;
      final allHubs = await EvuddyApi.hubs();
      EvuddyHub? h;
      for (final x in allHubs) {
        if (x.id == registrationDraft.chosenHubId) {
          h = x;
          break;
        }
      }
      h ??= allHubs.isEmpty ? null : allHubs.first;
      final bikes = await EvuddyApi.vehicles(city: city);
      final atHub = bikes.where((v) {
        if (h == null) return true;
        return _hubMatch(v.currentHub, h);
      }).toList()
        ..sort((a, b) => b.batteryPercentage.compareTo(a.batteryPercentage));

      RiderBooking? mine = booking;
      final token = await _token();
      if (token != null) {
        mine = await EvuddyApi.myBooking(token) ?? mine;
        if (mine != null) {
          registrationDraft.activeBooking = mine;
        }
      }

      if (!mounted) return;
      setState(() {
        hub = h;
        vehicles = atHub;
        selected = atHub.isEmpty ? null : atHub.first;
        booking = mine;
        loading = false;
        if (mine != null && mine.due > 0.009) {
          amount.text = mine.due.toStringAsFixed(0);
        } else if (!rental && amount.text.isEmpty) {
          amount.text = '${CatalogRates.securityDeposit}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  bool _hubMatch(String current, EvuddyHub h) {
    final aliases = [h.name, h.code, h.location, h.city]
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
    final t = current.trim().toLowerCase();
    if (t.isEmpty) return true;
    for (final a in aliases) {
      if (t == a || t.contains(a) || a.contains(t)) return true;
      final n1 = num.tryParse(t);
      final n2 = num.tryParse(a);
      if (n1 != null && n2 != null && n1 == n2) return true;
    }
    return false;
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
          d.riderId = looked.riderId;
          d.approvalStatus = looked.approvalStatus;
          d.bookingEnabled = looked.bookingEnabled;
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
      final created = await EvuddyApi.createBooking(
        idToken: token,
        userName: d.fullName.isEmpty ? 'Rider' : d.fullName,
        userPhone: d.phone,
        riderId: d.riderId!,
        vehicleId: bike.vehicleId,
        hub: h,
        city: d.chosenCity ?? h.city,
        rentalMode: rentalMode,
        duration: rental ? duration : 'Rent To Own',
        referenceBy: d.comingThrough,
      );
      registrationDraft
        ..activeBooking = created
        ..chosenDuration = duration;
      if (!mounted) return;
      setState(() {
        booking = created;
        busy = false;
        note = created.message.isEmpty
            ? (rental
                ? 'Scooter reserved. Pay from ₹1 to get pickup OTP.'
                : 'Scooter reserved. Pay ${CatalogRates.inr(CatalogRates.securityDeposit)} security deposit — hold only, not a recharge.')
            : created.message;
        if (created.due > 0.009) {
          amount.text = created.due.toStringAsFixed(0);
        } else if (!rental) {
          amount.text = '${CatalogRates.securityDeposit}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString();
      });
    }
  }

  Future<void> _pay() async {
    final token = await _token();
    final b = booking;
    if (token == null || b == null || b.mongoId.isEmpty) {
      setState(() => error = 'Reserve a scooter first.');
      return;
    }
    final maxDue = b.due;
    final pay = double.tryParse(amount.text.trim()) ?? 0;
    final depositOnly = !rental && maxDue < 0.01;
    if (pay < 1 || (!depositOnly && maxDue > 0.009 && pay > maxDue + 0.009)) {
      setState(() => error = depositOnly
          ? 'Enter the ${CatalogRates.inr(CatalogRates.securityDeposit)} hold (or the amount the yard billed).'
          : 'Enter a payment between ₹1 and ₹${maxDue.toStringAsFixed(0)}.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final order = await EvuddyApi.createRazorpayOrder(
        idToken: token,
        bookingMongoId: b.mongoId,
        amountRupees: pay,
      );
      if (!mounted) return;
      setState(() => busy = false);
      final result = await Navigator.push<Map<String, String>>(
        context,
        evuddyRoute(
          RazorpayCheckoutPage(
            order: order,
            bookingId: b.bookingId,
            contact: registrationDraft.phone,
            customerName: registrationDraft.fullName,
            rupees: pay,
            vehicleId: selected?.vehicleId ?? b.vehicleId,
          ),
        ),
      );
      if (result == null) return;
      setState(() => busy = true);
      final verified = await EvuddyApi.verifyPayment(
        idToken: token,
        bookingMongoId: b.mongoId,
        orderId: result['orderId'],
        paymentId: result['paymentId'],
        signature: result['signature'],
      );
      registrationDraft.activeBooking = verified;
      if (!rental && pay >= 1) {
        final held = (registrationDraft.depositHeld + pay)
            .clamp(0, CatalogRates.securityDeposit.toDouble())
            .toDouble();
        registrationDraft
          ..depositHeld = held
          ..depositStatus = 'held'
          ..depositBookingId = verified.bookingId.isEmpty ? b.bookingId : verified.bookingId;
      }
      if (verified.hasPickupOtp) {
        try {
          await EvuddyApi.notifyPickupOtp(
            idToken: token,
            bookingId: verified.bookingId.isEmpty ? b.bookingId : verified.bookingId,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        booking = verified;
        busy = false;
        note = verified.message.isEmpty
            ? 'Payment successful. Show pickup OTP at the yard.'
            : verified.message;
        if (verified.due > 0.009) {
          amount.text = verified.due.toStringAsFixed(0);
        }
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
    final token = await _token();
    if (token == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final msg = await EvuddyApi.rideAction(idToken: token, start: start);
      final mine = await EvuddyApi.myBooking(token);
      if (!start &&
          registrationDraft.depositHeld > 0 &&
          registrationDraft.depositStatus == 'held') {
        registrationDraft.depositStatus = 'refund_pending';
      }
      if (!mounted) return;
      setState(() {
        booking = mine ?? booking;
        busy = false;
        note = msg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = registrationDraft;
    final b = booking;
    return AuthScreen(
      kicker: rental ? 'Flexible rental' : 'Rent to Own',
      title: b != null && b.bookingId.isNotEmpty
          ? 'Booking ${b.bookingId}'
          : (rental ? 'Choose a duration' : '${CatalogRates.rtoMonths}-month ownership'),
      subtitle: rental
          ? 'GST included. First ₹1 issues pickup OTP. No recharge wallet.'
          : '${CatalogRates.inr(CatalogRates.rtoDaily)}/day · ${CatalogRates.rtoMonths} months · ${CatalogRates.inr(CatalogRates.securityDeposit)} hold, refunded when the scooter is back.',
      error: error,
      footer: _footer(b),
      children: [
        const ScenePhoto(asset: Evuddy.riderEveningAsset, height: 180),
        const SizedBox(height: 16),
        if (loading) const InfoNote(text: 'Loading live scooters…'),
        if (hub != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hub!.name} · ${hub!.location}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('${hub!.city} · ${rental ? duration : "Rent to Own"} · ${CatalogRates.gstNote}'),
                const SizedBox(height: 10),
                EvuddyGhostButton(
                  label: 'Open hub in Maps',
                  onPressed: () {
                    launchMaps(hub!.mapsQuery);
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (rental && b == null)
          ChoicePills(
            options: const ['Daily', 'Weekly', 'Monthly'],
            value: duration,
            onChanged: (v) => setState(() => duration = v),
          ),
        const SizedBox(height: 16),
        if (b == null) ...[
          Text('SCOOTER', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          if (!loading && vehicles.isEmpty)
            const InfoNote(
              text:
                  'No live scooter at this hub (same as evuddy.com). You can still open website Book EV, or wait for the yard to stock one.',
            ),
          for (final v in vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => selected = v),
                borderRadius: BorderRadius.circular(16),
                child: SurfaceCard(
                  child: Row(
                    children: [
                      Icon(
                        selected?.vehicleId == v.vehicleId
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected?.vehicleId == v.vehicleId
                            ? Evuddy.green
                            : Evuddy.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.registrationNumber.isEmpty
                                  ? v.vehicleModel
                                  : v.registrationNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${v.vehicleModel} · battery ${v.batteryPercentage.round()}%',
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
              ),
            ),
        ],
        if (b != null) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paid ₹${b.receivedAmount.toStringAsFixed(0)} · remaining ₹${b.due.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text('${b.paymentStatus} · ${b.rideStatus.isEmpty ? "Reserved" : b.rideStatus}'),
                if (b.vehicleNumber.isNotEmpty) Text(b.vehicleNumber),
              ],
            ),
          ),
          if (b.hasPickupOtp) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                children: [
                  Text('PICKUP OTP', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  SelectableText(
                    b.pickupOtp,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                  if (b.rideEndOtp.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('RIDE END OTP', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    SelectableText(
                      b.rideEndOtp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (b.due > 0.009 || needsDepositHold) ...[
            const SizedBox(height: 16),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: needsDepositHold && b.due < 0.01
                    ? 'Security deposit hold (₹)'
                    : 'Pay amount (₹1 to remaining)',
                filled: true,
                fillColor: Evuddy.paper,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
        if (note != null) ...[
          const SizedBox(height: 12),
          InfoNote(text: note!),
        ],
        const SizedBox(height: 8),
        Text(
          'City ${d.chosenCity ?? "—"} · ${CatalogRates.gstNote}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _footer(RiderBooking? b) {
    if (busy) {
      return const EvuddyButton(label: 'Working…', onPressed: null, busy: true);
    }
    if (b == null) {
      if (vehicles.isEmpty) {
        return Column(
          children: [
            EvuddyButton(
              label: 'Open Book EV on evuddy.com',
              onPressed: () => openEvuddyPath(
                rental ? '/book-bike?flow=rental' : '/rent-to-own',
              ),
            ),
            const SizedBox(height: 8),
            EvuddyGhostButton(label: 'Refresh scooters', onPressed: _load),
          ],
        );
      }
      return EvuddyButton(label: 'Reserve scooter', onPressed: _reserve);
    }
    if (b.due > 0.009 || needsDepositHold) {
      return EvuddyButton(
        label: needsDepositHold && b.due < 0.01
            ? 'Hold deposit on Razorpay'
            : 'Pay with Razorpay',
        onPressed: _pay,
      );
    }
    if (!b.pickupOtpVerified && b.hasPickupOtp && b.rideStatus != 'In Ride') {
      return EvuddyButton(
        label: 'Mark ride started',
        onPressed: () => _ride(true),
      );
    }
    if (b.rideStatus == 'In Ride' && b.due <= 0.009) {
      return EvuddyButton(
        label: 'Generate ride-end OTP',
        onPressed: () => _ride(false),
      );
    }
    return EvuddyButton(
      label: 'Refresh booking',
      onPressed: _load,
    );
  }
}
