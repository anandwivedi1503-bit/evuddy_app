import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks only to the live EVUDDY site. Keys stay on evuddy.com — never in the app.
class EvuddyApi {
  static const origin = 'https://www.evuddy.com';

  /// Keep-alive client so thousands of riders reuse TLS to evuddy.com.
  static final http.Client _http = http.Client();

  /// Public Razorpay key from create-order — same `keyId` Book EV keeps in the page.
  static const _keyPref = 'evuddy_rzp_key_v1';
  static String? _rzpKey;

  static Future<void> _rememberRzpKey(String key) async {
    if (!key.startsWith('rzp_')) return;
    _rzpKey = key;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_keyPref, key);
    } catch (_) {}
  }

  static Future<String> cachedRazorpayKey() async {
    if (_rzpKey != null && _rzpKey!.startsWith('rzp_')) return _rzpKey!;
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString(_keyPref) ?? '';
      if (saved.startsWith('rzp_')) _rzpKey = saved;
      return saved.startsWith('rzp_') ? saved : '';
    } catch (_) {
      return '';
    }
  }

  static Uri _u(String path, [Map<String, String>? query]) {
    return Uri.parse('$origin$path').replace(queryParameters: query);
  }

  static Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    Object? last;
    for (var i = 0; i < 3; i++) {
      try {
        return await _http.get(uri, headers: headers).timeout(timeout);
      } catch (e) {
        last = e;
        await Future<void>.delayed(Duration(milliseconds: 280 * (i + 1)));
      }
    }
    throw ApiException(last?.toString() ?? 'Could not reach evuddy.com.');
  }

  static Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    required Object body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    Object? last;
    for (var i = 0; i < 2; i++) {
      try {
        final r = await _http
            .post(uri, headers: headers, body: body)
            .timeout(timeout);
        if (r.statusCode == 429 && i == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 900));
          continue;
        }
        return r;
      } catch (e) {
        last = e;
        await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
      }
    }
    throw ApiException(last?.toString() ?? 'Could not reach evuddy.com.');
  }

  static Map<String, dynamic> _json(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) return body;
      return {'success': false, 'message': r.body};
    } catch (_) {
      return {'success': false, 'message': 'Unexpected response (${r.statusCode}).'};
    }
  }

  static Future<bool> health() async {
    try {
      final r = await _get(_u('/api/health'), timeout: const Duration(seconds: 8));
      final j = _json(r);
      return r.statusCode == 200 && j['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<RiderLookup> lookupRider({
    required String phone,
    required String idToken,
  }) async {
    final r = await _get(
      _u('/api/riders', {'phone': phone}),
      headers: {'Authorization': 'Bearer $idToken'},
      timeout: const Duration(seconds: 15),
    );
    final j = _json(r);
    if (r.statusCode == 404 || j['errorCode'] == 'RIDER_NOT_FOUND') {
      return const RiderLookup.missing();
    }
    if (j['success'] == true && j['data'] is Map) {
      return RiderLookup.fromData(j['data'] as Map, message: j['message']?.toString());
    }
    if (j['success'] == true && (j['riderId'] != null || j['approvalStatus'] != null)) {
      return RiderLookup.fromData(j, message: j['message']?.toString());
    }
    return RiderLookup(
      found: false,
      message: j['message']?.toString() ?? 'Could not look up this number.',
    );
  }

  static Future<String> uploadFile({
    required File file,
    required String idToken,
    String filename = 'document',
  }) async {
    final bytes = await file.readAsBytes();
    final kind = sniffImageBytes(bytes);
    final req = http.MultipartRequest('POST', _u('/api/upload'))
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['firebaseIdToken'] = idToken
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$filename.${kind.extension}',
          contentType: kind.mediaType,
        ),
      );
    final streamed = await req.send().timeout(const Duration(seconds: 45));
    final r = await http.Response.fromStream(streamed);
    final j = _json(r);
    final url = j['url']?.toString() ??
        (j['data'] is Map ? (j['data'] as Map)['url']?.toString() : null);
    if (j['success'] == true && url != null && url.isNotEmpty) return url;
    throw ApiException(
      j['error']?.toString() ?? j['message']?.toString() ?? 'File upload failed.',
    );
  }

  static Future<RegisterResult> createRider(Map<String, dynamic> body) async {
    final token = body['firebaseIdToken']?.toString();
    final r = await _post(
      _u('/api/riders'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    final j = _json(r);
    final errors = <String>[];
    final raw = j['errors'];
    if (raw is List) {
      errors.addAll(raw.map((e) => e.toString()));
    }
    return RegisterResult(
      ok: r.statusCode >= 200 && r.statusCode < 300 && j['success'] == true,
      statusCode: r.statusCode,
      message: j['message']?.toString() ?? (errors.isEmpty ? null : errors.join(' ')),
      errors: errors,
      riderExists: j['riderExists'] == true,
      riderId: (j['riderId'] ?? (j['data'] is Map ? (j['data'] as Map)['riderId'] : null))
          ?.toString(),
      riderStatus: j['riderStatus']?.toString() ??
          (j['data'] is Map ? (j['data'] as Map)['approvalStatus']?.toString() : null) ??
          j['approvalStatus']?.toString(),
      bookingEnabled: j['bookingEnabled'] == true ||
          (j['data'] is Map && (j['data'] as Map)['bookingEnabled'] == true) ||
          RiderLookup.isApprovedStatus(
            j['riderStatus']?.toString() ??
                (j['data'] is Map ? (j['data'] as Map)['approvalStatus']?.toString() : null) ??
                j['approvalStatus']?.toString() ??
                '',
          ),
    );
  }

  static Future<List<EvuddyCity>> cities() async {
    final r = await _get(_u('/api/cities'));
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => EvuddyCity(
              id: e['_id']?.toString() ?? '',
              name: e['cityName']?.toString() ?? '',
              state: e['state']?.toString() ?? '',
            ))
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  static Future<List<EvuddyHub>> hubs({String? city}) async {
    final r = await _get(
      _u('/api/hubs', city == null || city.isEmpty ? null : {'city': city}),
    );
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data
        .whereType<Map>()
        .map(EvuddyHub.fromJson)
        .where((h) => h.name.isNotEmpty)
        .toList();
  }

  static Future<List<EvuddyVehicle>> vehicles({String? city, String? hub}) async {
    Future<List<EvuddyVehicle>> fetch(Map<String, String>? query) async {
      final r = await _get(_u('/api/vehicles', query));
      final j = _json(r);
      final data = j['data'];
      if (j['success'] != true || data is! List) return [];
      return data
          .whereType<Map>()
          .map(EvuddyVehicle.fromJson)
          .where((v) => v.isBookable)
          .toList();
    }

    final query = <String, String>{
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (hub != null && hub.trim().isNotEmpty) 'hub': hub.trim().toUpperCase(),
    };
    var list = await fetch(query.isEmpty ? null : query);
    if (list.isEmpty && query.isNotEmpty) {
      list = await fetch(city != null && city.trim().isNotEmpty ? {'city': city.trim()} : null);
    }
    if (list.isEmpty && query.isNotEmpty) {
      list = await fetch(null);
    }
    return list;
  }

  static Map<String, String> _auth(String idToken) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

  static Future<RiderBooking?> myBooking(String idToken) async {
    final r = await _get(
      _u('/api/bookings/mine'),
      headers: _auth(idToken),
      timeout: const Duration(seconds: 15),
    );
    final j = _json(r);
    if (r.statusCode == 401 || j['success'] != true) {
      throw ApiException(_message(j, 'Unable to load your booking.'));
    }
    final data = j['data'];
    if (data is! Map) return null;
    return RiderBooking.fromJson(data);
  }

  static Future<RiderBooking> createBooking({
    required String idToken,
    required String userName,
    required String userPhone,
    required String riderId,
    required String vehicleId,
    required EvuddyHub hub,
    required String city,
    required String rentalMode,
    String? duration,
    String? referenceBy,
    String? bookingRequestId,
    RtoAgreement? rto,
  }) async {
    final requestId = (bookingRequestId != null && bookingRequestId.isNotEmpty)
        ? bookingRequestId
        : '${DateTime.now().microsecondsSinceEpoch}-$userPhone';
    final body = {
      'bookingRequestId': requestId,
      'userName': userName,
      'userPhone': userPhone,
      'riderId': riderId,
      'vehicleId': vehicleId,
      'startHub': hub.code.isNotEmpty ? hub.code : hub.name,
      'pickupHubName': hub.name.isNotEmpty ? hub.name : hub.location,
      'hubAliases': [
        hub.name,
        hub.code,
        hub.location,
        city,
      ].where((s) => s.isNotEmpty).toList(),
      'city': city,
      'pickupCity': city,
      'rentalMode': rentalMode,
      if (duration != null && duration.isNotEmpty) 'rentalDuration': duration,
      if (referenceBy != null && referenceBy.isNotEmpty) 'referenceBy': referenceBy,
      'firebaseIdToken': idToken,
      'paymentMode': 'Razorpay',
      'paymentStatus': 'Pending',
      if (rto != null) ...rto.toJson(),
    };
    final r = await _post(
      _u('/api/bookings'),
      headers: _auth(idToken),
      body: jsonEncode(body),
    );
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Booking failed.'));
    }
    final data = j['data'];
    if (data is Map) return RiderBooking.fromJson(data);
    final id = j['bookingId']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException('Booking was created but no booking ID was returned.');
    }
    return RiderBooking(bookingId: id);
  }

  static Future<PaymentStart> startPayment({
    required String idToken,
    required String bookingMongoId,
    required double amountRupees,
    bool useWallet = false,
  }) async {
    // Same body as live Book EV `payWithRazorpay` on evuddy.com.
    final r = await _post(
      _u('/api/razorpay/create-order'),
      headers: _auth(idToken),
      body: jsonEncode({
        'bookingMongoId': bookingMongoId,
        'amount': amountRupees,
        'firebaseIdToken': idToken,
        if (useWallet) 'useWallet': true,
        if (useWallet) 'paymentMethod': 'wallet',
      }),
    );
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(
        _message(
          j,
          useWallet ? 'Wallet payment failed.' : 'Unable to create Razorpay order.',
        ),
      );
    }
    if (j['paidWithWallet'] == true) {
      return PaymentStart.settled(
        booking: RiderBooking.fromJson(j),
        wallet: true,
      );
    }
    final booking = RiderBooking.fromJson(j);
    var order = RazorpayOrder.fromJson(j);
    if (order.keyId.isNotEmpty) await _rememberRzpKey(order.keyId);
    if (order.keyId.isEmpty) {
      final cached = await cachedRazorpayKey();
      if (cached.startsWith('rzp_')) {
        order = RazorpayOrder(
          keyId: cached,
          orderId: order.orderId,
          amount: order.amount,
          currency: order.currency,
          name: order.name,
          image: order.image,
        );
      }
    }
    final fullyPaid = booking.due <= 0.009;
    // Wallet or a fully paid booking can attach without Checkout. Remaining
    // due after a captured ₹1 must still open the pay screen — create-order
    // may return alreadyCaptured with no orderId until evuddy.com mints the
    // remaining order; checkout.js will call create-order again.
    if (fullyPaid &&
        (j['alreadyCaptured'] == true || order.orderId.isEmpty)) {
      return PaymentStart.settled(booking: booking);
    }
    if (order.orderId.startsWith('order_') && order.keyId.startsWith('rzp_')) {
      await _rememberRzpKey(order.keyId);
      return PaymentStart.checkout(
        RazorpayOrder(
          keyId: order.keyId,
          orderId: order.orderId,
          amount: order.amount > 0
              ? order.amount
              : (amountRupees * 100).roundToDouble(),
          currency: order.currency.isEmpty ? 'INR' : order.currency,
          name: order.name,
          image: order.image,
        ),
      );
    }
    return PaymentStart.bookEv(
      booking: booking,
      order: RazorpayOrder(
        keyId: order.keyId,
        orderId: order.orderId,
        amount: order.amount > 0
            ? order.amount
            : (amountRupees * 100).roundToDouble(),
        currency: order.currency.isEmpty ? 'INR' : order.currency,
        name: order.name,
        image: order.image,
      ),
    );
  }

  static Future<RazorpayOrder> createRazorpayOrder({
    required String idToken,
    required String bookingMongoId,
    required double amountRupees,
  }) async {
    final started = await startPayment(
      idToken: idToken,
      bookingMongoId: bookingMongoId,
      amountRupees: amountRupees,
    );
    if (started.order == null || !started.order!.orderId.startsWith('order_')) {
      throw ApiException('This amount is already settled on the booking.');
    }
    return started.order!;
  }

  static Future<List<RideHistoryItem>> bookingHistory(String idToken) async {
    final r = await _get(
      _u('/api/bookings/history'),
      headers: _auth(idToken),
      timeout: const Duration(seconds: 15),
    );
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data.whereType<Map>().map(RideHistoryItem.fromJson).toList();
  }

  static Future<List<PaymentReceipt>> myReceipts(String idToken) async {
    final r = await _get(
      _u('/api/receipts/mine'),
      headers: _auth(idToken),
      timeout: const Duration(seconds: 15),
    );
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data.whereType<Map>().map(PaymentReceipt.fromJson).toList();
  }

  static Future<void> submitReview({
    required String idToken,
    required String bookingId,
    required int stars,
    String comment = '',
    bool wouldRecommend = true,
  }) async {
    final r = await _post(
      _u('/api/reviews'),
      headers: _auth(idToken),
      body: jsonEncode({
        'bookingId': bookingId,
        'stars': stars,
        'vehicleStars': stars,
        'hubStars': stars,
        'comment': comment,
        'wouldRecommend': wouldRecommend,
        'firebaseIdToken': idToken,
      }),
    );
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Could not save your review.'));
    }
  }

  static Future<List<SupportTicket>> myTickets(String idToken) async {
    final r = await _get(
      _u('/api/tickets/mine'),
      headers: _auth(idToken),
      timeout: const Duration(seconds: 15),
    );
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data.whereType<Map>().map(SupportTicket.fromJson).toList();
  }

  static Future<SupportTicket> createTicket({
    required String idToken,
    required String bookingId,
    required String userId,
    required String category,
    required String description,
  }) async {
    final r = await _post(
      _u('/api/tickets'),
      headers: _auth(idToken),
      body: jsonEncode({
        'ticketId': 'BK-${DateTime.now().millisecondsSinceEpoch}',
        'bookingId': bookingId,
        'userId': userId,
        'category': category,
        'description': description,
        'firebaseIdToken': idToken,
      }),
    );
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Could not send support ticket.'));
    }
    final data = j['data'];
    if (data is Map) return SupportTicket.fromJson(data);
    return SupportTicket(
      ticketId: j['ticketId']?.toString() ?? '',
      category: category,
      status: 'OPEN',
      description: description,
    );
  }

  static Future<Map<String, dynamic>> _postVerifyPayment({
    required String idToken,
    required String bookingMongoId,
    String? orderId,
    String? paymentId,
    String? signature,
    bool recover = false,
  }) async {
    final r = await _post(
      _u('/api/razorpay/verify-payment'),
      headers: _auth(idToken),
      body: jsonEncode({
        'bookingMongoId': bookingMongoId,
        'firebaseIdToken': idToken,
        if (recover) 'recover': true,
        'razorpay_order_id': ?orderId,
        'razorpay_payment_id': ?paymentId,
        'razorpay_signature': ?signature,
      }),
    );
    return _json(r);
  }

  static Future<RiderBooking> verifyPayment({
    required String idToken,
    required String bookingMongoId,
    String? orderId,
    String? paymentId,
    String? signature,
    bool recover = false,
  }) async {
    Map<String, dynamic>? j;
    if (!recover) {
      for (var i = 0; i < 3; i++) {
        j = await _postVerifyPayment(
          idToken: idToken,
          bookingMongoId: bookingMongoId,
          orderId: orderId,
          paymentId: paymentId,
          signature: signature,
        );
        if (j['success'] == true) break;
        if (i < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }
      }
    }
    if (j == null || j['success'] != true) {
      j = await _postVerifyPayment(
        idToken: idToken,
        bookingMongoId: bookingMongoId,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        recover: true,
      );
    }
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Could not verify payment.'));
    }
    return RiderBooking.fromJson(j);
  }

  static Future<void> notifyPickupOtp({
    required String idToken,
    required String bookingId,
  }) async {
    await _post(
      _u('/api/notify/booking-otp'),
      headers: _auth(idToken),
      body: jsonEncode({'bookingId': bookingId}),
      timeout: const Duration(seconds: 15),
    );
  }

  static Future<RideActionResult> rideAction({
    required String idToken,
    required bool start,
    String? bookingId,
  }) async {
    final r = await _post(
      _u(start ? '/api/rides/rider-start' : '/api/rides/rider-end'),
      headers: _auth(idToken),
      body: jsonEncode({
        'firebaseIdToken': idToken,
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
      }),
      timeout: const Duration(seconds: 15),
    );
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Unable to update ride.'));
    }
    final booking = RiderBooking.fromJson(j);
    return RideActionResult(
      message: j['message']?.toString() ??
          (start
              ? 'Ride started. Pay any remaining amount before you return.'
              : 'Ride end OTP is ready. Tell this to the yard to return the scooter.'),
      rideEndOtp: booking.rideEndOtp,
      rideStatus: booking.rideStatus,
    );
  }

  static String _message(Map<String, dynamic> j, String fallback) {
    final errors = j['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.map((e) => e.toString()).join(' ');
    }
    return j['details']?.toString() ?? j['message']?.toString() ?? fallback;
  }
}

/// Rider catalog. GST-in rental prices; RTO is ₹300/day + ₹2,500 hold.
class CatalogRates {
  static const hourly = 60;
  static const daily = 250;
  static const weekly = 1750;
  static const monthly = 7500;
  static const rtoDaily = 300;
  static const rtoMonths = 20;
  static const securityDeposit = 2500;
  static const gstNote = 'GST included on rental';
  static const partnerMonths = 48;
  static const partnerMinFleet = 5;
  static const lowSpeedPerScooter = 60000;
  static const highSpeedPerScooter = 90000;
  static const lowSpeedMonthlyForFive = 15000;
  static const highSpeedMonthlyForFive = 18000;

  static String inr(num n) {
    final s = n.round().abs().toString();
    final buf = StringBuffer();
    if (s.length <= 3) {
      return '₹${n.round() < 0 ? '-' : ''}$s';
    }
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    buf.write(n.round() < 0 ? '-₹' : '₹');
    buf.write(groups.join(','));
    buf.write(',$last3');
    return buf.toString();
  }

  static int lowSpeedMonthly(int fleet) => 3000 * fleet;

  static int highSpeedMonthly(int fleet) => 3600 * fleet;

  static Map<String, dynamic> payload() => {
        'hourly': hourly,
        'daily': daily,
        'weekly': weekly,
        'monthly': monthly,
        'rtoDaily': rtoDaily,
        'rtoMonths': rtoMonths,
        'securityDeposit': securityDeposit,
        'gstInclusiveRental': true,
        'currency': 'INR',
      };

  static int amountForDuration(String duration) {
    switch (duration) {
      case 'Hourly':
        return hourly;
      case 'Weekly':
        return weekly;
      case 'Monthly':
        return monthly;
      case 'Rent to Own':
      case 'Rent To Own':
        return rtoDaily;
      default:
        return daily;
    }
  }

  /// Website Book EV: GST-included fare + refundable ₹2,500 deposit.
  static int payableForDuration(String duration) =>
      amountForDuration(duration) + securityDeposit;

  static GstSplit gstInclusive(num inclusive) {
    final total = _money(inclusive);
    final taxable = _money(total / 1.05);
    final gst = _money(total - taxable);
    final cgst = _money(gst / 2);
    final sgst = _money(gst - cgst);
    return GstSplit(
      taxable: taxable,
      cgst: cgst,
      sgst: sgst,
      gst: gst,
      total: total,
    );
  }
}

double _money(num n) => double.parse(n.toDouble().toStringAsFixed(2));

class RtoAgreement {
  const RtoAgreement({
    required this.nomineeName,
    required this.nomineeRelation,
    required this.guardianName,
    required this.emergencyPhone,
    required this.email,
    required this.address,
    required this.occupation,
    required this.agreed,
  });

  static const relations = [
    'Spouse',
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Other',
  ];

  static final namePattern = RegExp(r"^[A-Za-z][A-Za-z\s'.-]{2,79}$");
  static final phonePattern = RegExp(r'^[6-9]\d{9}$');
  static final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  final String nomineeName;
  final String nomineeRelation;
  final String guardianName;
  final String emergencyPhone;
  final String email;
  final String address;
  final String occupation;
  final bool agreed;

  String? get validationError {
    if (!namePattern.hasMatch(nomineeName.trim())) {
      return 'Nominee name is required for Rent to Own.';
    }
    if (!relations.contains(nomineeRelation)) {
      return 'Nominee relation is required for Rent to Own.';
    }
    if (!namePattern.hasMatch(guardianName.trim())) {
      return 'Father / guardian name is required for Rent to Own.';
    }
    if (!phonePattern.hasMatch(emergencyPhone.replaceAll(RegExp(r'\D'), ''))) {
      return 'Valid emergency contact number is required for Rent to Own.';
    }
    if (!emailPattern.hasMatch(email.trim().toLowerCase())) {
      return 'Valid email is required for Rent to Own.';
    }
    if (address.trim().length < 12) {
      return 'Permanent address is required for Rent to Own.';
    }
    if (occupation.trim().length < 2) {
      return 'Occupation is required for Rent to Own.';
    }
    if (!agreed) {
      return 'You must accept the Rent to Own ownership agreement.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'rtoNomineeName': nomineeName.trim(),
        'rtoNomineeRelation': nomineeRelation,
        'rtoGuardianName': guardianName.trim(),
        'rtoEmergencyPhone': emergencyPhone.replaceAll(RegExp(r'\D'), ''),
        'rtoEmail': email.trim().toLowerCase(),
        'rtoPermanentAddress': address.trim(),
        'rtoOccupation': occupation.trim(),
        'rtoAgreementAccepted': agreed,
      };
}

class RideHistoryItem {
  const RideHistoryItem({
    this.bookingId = '',
    this.rideStatus = '',
    this.rentalMode = '',
    this.vehicleId = '',
    this.vehicleModel = '',
    this.hub = '',
    this.city = '',
    this.receivedAmount = 0,
    this.canReview = false,
    this.reviewStars,
  });

  factory RideHistoryItem.fromJson(Map e) {
    return RideHistoryItem(
      bookingId: e['bookingId']?.toString() ?? '',
      rideStatus: e['rideStatus']?.toString() ?? '',
      rentalMode: e['rentalMode']?.toString() ?? '',
      vehicleId: e['vehicleId']?.toString() ?? '',
      vehicleModel: e['vehicleModel']?.toString() ?? '',
      hub: (e['pickupHubName'] ?? e['startHub'])?.toString() ?? '',
      city: (e['pickupCity'] ?? e['city'])?.toString() ?? '',
      receivedAmount: _asDouble(e['receivedAmount']) ?? 0,
      canReview: e['canReview'] == true,
      reviewStars: (e['reviewStars'] is num) ? (e['reviewStars'] as num).toInt() : null,
    );
  }

  final String bookingId;
  final String rideStatus;
  final String rentalMode;
  final String vehicleId;
  final String vehicleModel;
  final String hub;
  final String city;
  final double receivedAmount;
  final bool canReview;
  final int? reviewStars;
}

class PaymentReceipt {
  const PaymentReceipt({
    this.transactionId = '',
    this.bookingId = '',
    this.amount = 0,
    this.paymentMethod = '',
    this.invoiceNumber = '',
  });

  factory PaymentReceipt.fromJson(Map e) {
    return PaymentReceipt(
      transactionId: e['transactionId']?.toString() ?? '',
      bookingId: e['bookingId']?.toString() ?? '',
      amount: _asDouble(e['amount']) ?? 0,
      paymentMethod: e['paymentMethod']?.toString() ?? '',
      invoiceNumber: e['invoiceNumber']?.toString() ?? '',
    );
  }

  final String transactionId;
  final String bookingId;
  final double amount;
  final String paymentMethod;
  final String invoiceNumber;
}

class GstSplit {
  const GstSplit({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.gst,
    required this.total,
  });
  final double taxable;
  final double cgst;
  final double sgst;
  final double gst;
  final double total;
}

class PaymentStart {
  const PaymentStart.checkout(this.order, {this.bookEvFlow = false})
      : booking = null,
        wallet = false;
  const PaymentStart.settled({required this.booking, this.wallet = false})
      : order = null,
        bookEvFlow = false;
  const PaymentStart.bookEv({this.order, this.booking})
      : wallet = false,
        bookEvFlow = true;

  final RazorpayOrder? order;
  final RiderBooking? booking;
  final bool wallet;
  final bool bookEvFlow;

  bool get needsCheckout =>
      order != null &&
      order!.keyId.startsWith('rzp_') &&
      order!.orderId.startsWith('order_');

  /// Open the in-app Razorpay screen. Remaining due after ₹1 is not "paid".
  bool get shouldOpenCheckoutSheet =>
      !wallet && (needsCheckout || bookEvFlow || (booking != null && booking!.due > 0.009));
}

class SupportTicket {
  const SupportTicket({
    this.ticketId = '',
    this.bookingId = '',
    this.category = '',
    this.status = '',
    this.description = '',
    this.adminRemarks = '',
  });

  factory SupportTicket.fromJson(Map e) {
    return SupportTicket(
      ticketId: e['ticketId']?.toString() ?? '',
      bookingId: e['bookingId']?.toString() ?? '',
      category: e['category']?.toString() ?? '',
      status: e['status']?.toString() ?? '',
      description: e['description']?.toString() ?? '',
      adminRemarks: e['adminRemarks']?.toString() ?? '',
    );
  }

  final String ticketId;
  final String bookingId;
  final String category;
  final String status;
  final String description;
  final String adminRemarks;
}

class EvuddyCity {
  const EvuddyCity({required this.id, required this.name, required this.state});
  final String id;
  final String name;
  final String state;
}

class EvuddyHub {
  const EvuddyHub({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.city,
    this.latitude,
    this.longitude,
  });

  factory EvuddyHub.fromJson(Map e) {
    return EvuddyHub(
      id: e['_id']?.toString() ?? '',
      name: e['hubName']?.toString() ?? '',
      code: e['hubCode']?.toString() ?? '',
      location: e['hubLocation']?.toString() ?? '',
      city: e['city']?.toString() ?? '',
      latitude: _asDouble(e['latitude']),
      longitude: _asDouble(e['longitude']),
    );
  }

  final String id;
  final String name;
  final String code;
  final String location;
  final String city;
  final double? latitude;
  final double? longitude;

  String get mapsQuery {
    final lat = latitude;
    final lng = longitude;
    if (lat != null &&
        lng != null &&
        lat >= 6 &&
        lat <= 37 &&
        lng >= 68 &&
        lng <= 98) {
      return '$lat,$lng';
    }
    return [name, location, city].where((s) => s.isNotEmpty).join(', ');
  }
}

class EvuddyVehicle {
  const EvuddyVehicle({
    required this.id,
    required this.vehicleId,
    required this.registrationNumber,
    required this.vehicleModel,
    required this.currentHub,
    required this.batteryPercentage,
    this.hourlyRate,
    this.dailyRate,
    this.vehicleStatus = 'Available',
  });

  factory EvuddyVehicle.fromJson(Map e) {
    final vid = e['vehicleId']?.toString() ?? e['_id']?.toString() ?? '';
    return EvuddyVehicle(
      id: e['_id']?.toString() ?? vid,
      vehicleId: vid,
      registrationNumber: e['registrationNumber']?.toString() ??
          e['vehicleNumber']?.toString() ??
          '',
      vehicleModel:
          e['vehicleModel']?.toString() ?? 'EVUDDY Electric Scooter',
      currentHub: e['currentHub']?.toString() ?? '',
      batteryPercentage: _asDouble(e['batteryPercentage']) ?? 0,
      hourlyRate: _asDouble(e['hourlyRate']),
      dailyRate: _asDouble(e['dailyRate']),
      vehicleStatus: e['vehicleStatus']?.toString() ?? 'Available',
    );
  }

  final String id;
  final String vehicleId;
  final String registrationNumber;
  final String vehicleModel;
  final String currentHub;
  final double batteryPercentage;
  final double? hourlyRate;
  final double? dailyRate;
  final String vehicleStatus;

  /// Same as evuddy.com Book EV: Available, or blank from a public list.
  bool get isBookable {
    final s = vehicleStatus.trim().toLowerCase();
    return s.isEmpty || s == 'available';
  }

  String get displayId =>
      vehicleId.isNotEmpty
          ? vehicleId
          : (registrationNumber.isNotEmpty ? registrationNumber : vehicleModel);
}

/// Hub codes like `01` match `1`, and names/locations match as on the website.
bool hubMatches(String currentHub, EvuddyHub hub) {
  final aliases = [hub.name, hub.code, hub.location, hub.city]
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();
  final t = currentHub.trim().toLowerCase();
  if (t.isEmpty) return true;
  for (final a in aliases) {
    if (t == a || t.contains(a) || a.contains(t)) return true;
    final n1 = num.tryParse(t);
    final n2 = num.tryParse(a);
    if (n1 != null && n2 != null && n1 == n2) return true;
  }
  return false;
}

class RiderBooking {
  const RiderBooking({
    this.mongoId = '',
    this.bookingId = '',
    this.rentalMode = '',
    this.paymentStatus = '',
    this.rideStatus = '',
    this.pendingAmount = 0,
    this.receivedAmount = 0,
    this.paymentDue = 0,
    this.pickupOtp = '',
    this.rideEndOtp = '',
    this.pickupOtpVerified = false,
    this.vehicleId = '',
    this.vehicleModel = '',
    this.vehicleNumber = '',
    this.startHub = '',
    this.pickupHubName = '',
    this.city = '',
    this.securityDeposit = 0,
    this.message = '',
  });

  factory RiderBooking.fromJson(Map e) {
    final nested = e['data'];
    final booking = e['booking'];
    final m = nested is Map
        ? nested
        : (booking is Map ? booking : e);
    var pending = _asDouble(
          m['pendingAmount'] ??
              e['pendingAmount'] ??
              m['remainingAmount'] ??
              e['remainingAmount'],
        ) ??
        0;
    final topRemaining =
        _asDouble(e['remainingAmount'] ?? e['pendingAmount']) ?? 0;
    if (pending <= 0.009 && topRemaining > 0.009) pending = topRemaining;
    final received = _asDouble(
          m['receivedAmount'] ?? e['receivedAmount'] ?? e['paidAmount'] ?? m['paidAmount'],
        ) ??
        0;
    final billed = _asDouble(m['paymentDue'] ?? e['paymentDue']) ?? 0;
    return RiderBooking(
      mongoId: m['_id']?.toString() ??
          m['id']?.toString() ??
          e['bookingMongoId']?.toString() ??
          e['_id']?.toString() ??
          '',
      bookingId: m['bookingId']?.toString() ?? e['bookingId']?.toString() ?? '',
      rentalMode: m['rentalMode']?.toString() ?? '',
      paymentStatus: (m['paymentStatus'] ?? e['paymentStatus'])?.toString() ?? '',
      rideStatus: (m['rideStatus'] ?? e['rideStatus'])?.toString() ?? '',
      pendingAmount: pending,
      receivedAmount: received,
      paymentDue: billed,
      pickupOtp: (m['pickupOTP'] ??
              m['pickupOtp'] ??
              e['pickupOTP'] ??
              e['pickupOtp'])
          ?.toString() ??
          '',
      rideEndOtp: (m['rideEndOTP'] ??
              m['rideEndOtp'] ??
              e['rideEndOTP'] ??
              e['rideEndOtp'])
          ?.toString() ??
          '',
      pickupOtpVerified: m['pickupOTPVerified'] == true || e['pickupOTPVerified'] == true,
      vehicleId: m['vehicleId']?.toString() ?? '',
      vehicleModel: m['vehicleModel']?.toString() ?? '',
      vehicleNumber: (m['vehicleNumber'] ?? m['registrationNumber'])?.toString() ?? '',
      startHub: m['startHub']?.toString() ?? '',
      pickupHubName: m['pickupHubName']?.toString() ?? '',
      city: (m['pickupCity'] ?? m['city'])?.toString() ?? '',
      securityDeposit: _asDouble(m['securityDeposit'] ?? e['securityDeposit']) ??
          CatalogRates.securityDeposit.toDouble(),
      message: e['message']?.toString() ?? '',
    );
  }

  final String mongoId;
  final String bookingId;
  final String rentalMode;
  final String paymentStatus;
  final String rideStatus;
  final double pendingAmount;
  final double receivedAmount;
  final double paymentDue;
  final String pickupOtp;
  final String rideEndOtp;
  final bool pickupOtpVerified;
  final String vehicleId;
  final String vehicleModel;
  final String vehicleNumber;
  final String startHub;
  final String pickupHubName;
  final String city;
  final double securityDeposit;
  final String message;

  /// Remaining Razorpay due — same rules as evuddy.com (`pendingAmount` /
  /// `remainingAmount`, else `paymentDue` minus already received).
  double get due {
    if (pendingAmount > 0.009) return pendingAmount;
    if (paymentDue > 0.009) {
      if (receivedAmount > 0.009 && paymentDue > receivedAmount + 0.009) {
        return paymentDue - receivedAmount;
      }
      return paymentDue;
    }
    return 0;
  }

  bool get hasPickupOtp => pickupOtp.isNotEmpty;

  bool get isRemainingPayment =>
      receivedAmount >= 1 || hasPickupOtp || pickupOtpVerified;

  /// Website locks remaining amount after first pay, and always for Rent to Own.
  bool get remainingPayLocked => isRentToOwn || isRemainingPayment;

  bool get completed {
    final s = rideStatus.toLowerCase();
    return s == 'completed' || s.contains('complete');
  }

  /// Yard has accepted pickup OTP. Rider still swipes start (same as evuddy.com).
  bool get readyForPickup {
    final s = rideStatus.toLowerCase();
    return pickupOtpVerified ||
        s == 'ready for pickup' ||
        s.contains('ready for pickup');
  }

  /// Live ride only after rider-start — pickup verified is not In Ride.
  bool get inRide => rideStatus.toLowerCase() == 'in ride';

  bool get isRentToOwn {
    final m = rentalMode.toLowerCase();
    return m.contains('own') || m.contains('rto');
  }

  RiderBooking copy({
    String? rideEndOtp,
    String? rideStatus,
    String? pickupOtp,
    String? message,
  }) {
    return RiderBooking(
      mongoId: mongoId,
      bookingId: bookingId,
      rentalMode: rentalMode,
      paymentStatus: paymentStatus,
      rideStatus: rideStatus ?? this.rideStatus,
      pendingAmount: pendingAmount,
      receivedAmount: receivedAmount,
      paymentDue: paymentDue,
      pickupOtp: pickupOtp ?? this.pickupOtp,
      rideEndOtp: rideEndOtp ?? this.rideEndOtp,
      pickupOtpVerified: pickupOtpVerified,
      vehicleId: vehicleId,
      vehicleModel: vehicleModel,
      vehicleNumber: vehicleNumber,
      startHub: startHub,
      pickupHubName: pickupHubName,
      city: city,
      securityDeposit: securityDeposit,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() => {
        'mongoId': mongoId,
        '_id': mongoId,
        'bookingId': bookingId,
        'rentalMode': rentalMode,
        'paymentStatus': paymentStatus,
        'rideStatus': rideStatus,
        'pendingAmount': pendingAmount,
        'receivedAmount': receivedAmount,
        'paymentDue': paymentDue,
        'pickupOTP': pickupOtp,
        'rideEndOTP': rideEndOtp,
        'pickupOTPVerified': pickupOtpVerified,
        'vehicleId': vehicleId,
        'vehicleModel': vehicleModel,
        'vehicleNumber': vehicleNumber,
        'startHub': startHub,
        'pickupHubName': pickupHubName,
        'city': city,
        'securityDeposit': securityDeposit,
        'message': message,
      };

  RiderBooking mergedWith(RiderBooking live) {
    final preferLive = live.receivedAmount + 0.009 >= receivedAmount;
    return RiderBooking(
      mongoId: live.mongoId.isNotEmpty ? live.mongoId : mongoId,
      bookingId: live.bookingId.isNotEmpty ? live.bookingId : bookingId,
      rentalMode: live.rentalMode.isNotEmpty ? live.rentalMode : rentalMode,
      paymentStatus:
          live.paymentStatus.isNotEmpty ? live.paymentStatus : paymentStatus,
      rideStatus: live.rideStatus.isNotEmpty ? live.rideStatus : rideStatus,
      pendingAmount: preferLive ? live.pendingAmount : pendingAmount,
      receivedAmount: preferLive ? live.receivedAmount : receivedAmount,
      paymentDue: live.paymentDue > 0.009 ? live.paymentDue : paymentDue,
      pickupOtp: live.pickupOtp.isNotEmpty ? live.pickupOtp : pickupOtp,
      rideEndOtp: live.rideEndOtp.isNotEmpty ? live.rideEndOtp : rideEndOtp,
      pickupOtpVerified: live.pickupOtpVerified || pickupOtpVerified,
      vehicleId: live.vehicleId.isNotEmpty ? live.vehicleId : vehicleId,
      vehicleModel: live.vehicleModel.isNotEmpty ? live.vehicleModel : vehicleModel,
      vehicleNumber:
          live.vehicleNumber.isNotEmpty ? live.vehicleNumber : vehicleNumber,
      startHub: live.startHub.isNotEmpty ? live.startHub : startHub,
      pickupHubName:
          live.pickupHubName.isNotEmpty ? live.pickupHubName : pickupHubName,
      city: live.city.isNotEmpty ? live.city : city,
      securityDeposit:
          live.securityDeposit > 0.009 ? live.securityDeposit : securityDeposit,
      message: message.isNotEmpty ? message : live.message,
    );
  }
}

class RazorpayOrder {
  const RazorpayOrder({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
    this.name = 'EVUDDY',
    this.image,
  });

  factory RazorpayOrder.fromJson(Map e) {
    final data = e['data'] is Map ? e['data'] as Map : const {};
    final booking = e['booking'] is Map ? e['booking'] as Map : const {};
    String pick(List<String> keys) {
      for (final k in keys) {
        for (final src in [e, data, booking]) {
          final v = src[k];
          if (v != null && v.toString().trim().isNotEmpty) {
            return v.toString().trim();
          }
        }
      }
      return '';
    }

    String pickKey() {
      final raw = pick(['keyId', 'key', 'key_id', 'razorpayKeyId', 'razorpay_key']);
      return raw.startsWith('rzp_') ? raw : '';
    }

    String pickOrder() {
      for (final k in ['orderId', 'order_id']) {
        final raw = pick([k]);
        if (raw.startsWith('order_')) return raw;
      }
      return '';
    }

    final name = pick(['name', 'merchantName', 'businessName']);
    return RazorpayOrder(
      keyId: pickKey(),
      orderId: pickOrder(),
      amount: _asDouble(e['amount']) ?? _asDouble(data['amount']) ?? 0,
      currency: pick(['currency']).isEmpty ? 'INR' : pick(['currency']),
      name: name.isEmpty ? 'Shubhrax Mobility Limited' : name,
      image: pick(['image']).isEmpty ? null : pick(['image']),
    );
  }

  final String keyId;
  final String orderId;
  final double amount;
  final String currency;
  final String name;
  final String? image;

  /// Razorpay Checkout wants paise. Live create-order may return paise or rupees.
  int amountPaise(double rupeesPaid) {
    final expected = (rupeesPaid * 100).round();
    final raw = amount.round();
    if (raw == expected) return raw;
    if (raw == rupeesPaid.round()) return expected;
    if (raw >= expected) return raw;
    return expected;
  }
}

/// Gallery compress often writes JPEG bytes while keeping a .png/.webp name.
/// Live /api/upload rejects that mismatch ("File content does not match…").
class SniffedImage {
  const SniffedImage(this.extension, this.mediaType);
  final String extension;
  final MediaType mediaType;
}

SniffedImage sniffImageBytes(List<int> bytes) {
  if (bytes.length < 12) {
    throw ApiException('That photo is empty or damaged. Pick it again.');
  }
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return SniffedImage('jpg', MediaType('image', 'jpeg'));
  }
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return SniffedImage('png', MediaType('image', 'png'));
  }
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return SniffedImage('webp', MediaType('image', 'webp'));
  }
  throw ApiException(
    'Use a JPEG, PNG or WebP from Camera or Gallery. WhatsApp/HEIC files are not accepted.',
  );
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RideActionResult {
  const RideActionResult({
    required this.message,
    this.rideEndOtp = '',
    this.rideStatus = '',
  });

  final String message;
  final String rideEndOtp;
  final String rideStatus;
}

class RiderLookup {
  const RiderLookup({
    required this.found,
    this.riderId,
    this.approvalStatus = '',
    this.bookingEnabled = false,
    this.fullName,
    this.email,
    this.message,
    this.walletAvailable = 0,
    this.walletStatus = '',
  });
  const RiderLookup.missing() : this(found: false);

  factory RiderLookup.fromData(Map d, {String? message}) {
    final status = (d['approvalStatus'] ??
            d['riderStatus'] ??
            d['status'] ??
            d['kycStatus'] ??
            d['riderApprovalStatus'] ??
            '')
        .toString();
    final enabled = d['bookingEnabled'] == true ||
        d['canBook'] == true ||
        d['bookingAllowed'] == true ||
        d['isApproved'] == true ||
        isApprovedStatus(status);
    return RiderLookup(
      found: true,
      riderId: (d['riderId'] ?? d['_id'] ?? d['id'])?.toString(),
      approvalStatus: status,
      bookingEnabled: enabled,
      fullName: (d['fullName'] ?? d['name'])?.toString(),
      email: d['email']?.toString(),
      message: message,
      walletAvailable: _asDouble(d['walletAvailable'] ?? d['walletBalance']) ?? 0,
      walletStatus: d['walletStatus']?.toString() ?? '',
    );
  }

  static String _norm(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');

  static bool isApprovedStatus(String raw) {
    final t = _norm(raw);
    if (t.isEmpty) return false;
    if (t.contains('reject') || t.contains('block') || t.contains('suspend')) {
      return false;
    }
    return t == 'approved' ||
        t == 'active' ||
        t == 'verified' ||
        t == 'enabled' ||
        t.startsWith('approved');
  }

  static bool isRejectedStatus(String raw) {
    final t = _norm(raw);
    return t.contains('reject') || t.contains('block') || t == 'suspended';
  }

  static bool isPendingStatus(String raw) {
    final t = _norm(raw);
    if (t.isEmpty) return true;
    if (isApprovedStatus(raw) || isRejectedStatus(raw)) return false;
    return t.contains('review') ||
        t.contains('pending') ||
        t.contains('submit') ||
        t.contains('kyc') ||
        t.contains('wait');
  }

  final bool found;
  final String? riderId;
  final String approvalStatus;
  final bool bookingEnabled;
  final String? fullName;
  final String? email;
  final String? message;
  final double walletAvailable;
  final String walletStatus;

  bool get walletBlocked =>
      walletStatus.toLowerCase().contains('block');
}

class RegisterResult {
  RegisterResult({
    required this.ok,
    required this.statusCode,
    this.message,
    this.errors = const [],
    this.riderExists = false,
    this.riderId,
    this.riderStatus,
    this.bookingEnabled = false,
  });

  final bool ok;
  final int statusCode;
  final String? message;
  final List<String> errors;
  final bool riderExists;
  final String? riderId;
  final String? riderStatus;
  final bool bookingEnabled;
}
