import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Talks only to the live EVUDDY site. Never writes website source.
class EvuddyApi {
  static const origin = 'https://www.evuddy.com';

  static Uri _u(String path, [Map<String, String>? query]) {
    return Uri.parse('$origin$path').replace(queryParameters: query);
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
      final r = await http.get(_u('/api/health')).timeout(const Duration(seconds: 8));
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
    final r = await http
        .get(
          _u('/api/riders', {'phone': phone}),
          headers: {'Authorization': 'Bearer $idToken'},
        )
        .timeout(const Duration(seconds: 15));
    final j = _json(r);
    if (r.statusCode == 404 || j['errorCode'] == 'RIDER_NOT_FOUND') {
      return const RiderLookup.missing();
    }
    if (j['success'] == true && j['data'] is Map) {
      final d = j['data'] as Map;
      return RiderLookup(
        found: true,
        riderId: d['riderId']?.toString(),
        approvalStatus: d['approvalStatus']?.toString() ?? '',
        bookingEnabled: d['bookingEnabled'] == true,
        message: j['message']?.toString(),
      );
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
    final r = await http
        .post(
          _u('/api/riders'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
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
          (j['data'] is Map ? (j['data'] as Map)['approvalStatus']?.toString() : null),
    );
  }

  static Future<List<EvuddyCity>> cities() async {
    final r = await http.get(_u('/api/cities')).timeout(const Duration(seconds: 12));
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

  static Future<List<EvuddyHub>> hubs() async {
    final r = await http.get(_u('/api/hubs')).timeout(const Duration(seconds: 12));
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data
        .whereType<Map>()
        .map(EvuddyHub.fromJson)
        .where((h) => h.name.isNotEmpty)
        .toList();
  }

  static Future<List<EvuddyVehicle>> vehicles({String? city}) async {
    final r = await http
        .get(_u('/api/vehicles', city == null ? null : {'city': city}))
        .timeout(const Duration(seconds: 12));
    final j = _json(r);
    final data = j['data'];
    if (j['success'] != true || data is! List) return [];
    return data.whereType<Map>().map(EvuddyVehicle.fromJson).toList();
  }

  static Map<String, String> _auth(String idToken) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

  static Future<RiderBooking?> myBooking(String idToken) async {
    final r = await http
        .get(_u('/api/bookings/mine'), headers: _auth(idToken))
        .timeout(const Duration(seconds: 15));
    final j = _json(r);
    if (j['success'] != true) return null;
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
  }) async {
    final body = {
      'bookingRequestId':
          '${DateTime.now().microsecondsSinceEpoch}-$userPhone',
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
      'catalog': CatalogRates.payload(),
      'securityDepositInr': rentalMode.toLowerCase().contains('own')
          ? CatalogRates.securityDeposit
          : 0,
      'depositHoldOnly': true,
      if (referenceBy != null && referenceBy.isNotEmpty) 'referenceBy': referenceBy,
      'firebaseIdToken': idToken,
      'paymentMode': 'Razorpay',
      'paymentStatus': 'Pending',
    };
    final r = await http
        .post(
          _u('/api/bookings'),
          headers: _auth(idToken),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
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

  static Future<RazorpayOrder> createRazorpayOrder({
    required String idToken,
    required String bookingMongoId,
    required double amountRupees,
  }) async {
    final r = await http
        .post(
          _u('/api/razorpay/create-order'),
          headers: _auth(idToken),
          body: jsonEncode({
            'bookingMongoId': bookingMongoId,
            'amount': amountRupees,
            'firebaseIdToken': idToken,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Unable to create Razorpay order.'));
    }
    return RazorpayOrder.fromJson(j);
  }

  static Future<RiderBooking> verifyPayment({
    required String idToken,
    required String bookingMongoId,
    String? orderId,
    String? paymentId,
    String? signature,
    bool recover = false,
  }) async {
    final r = await http
        .post(
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
        )
        .timeout(const Duration(seconds: 20));
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Could not verify payment.'));
    }
    return RiderBooking.fromJson(j);
  }

  static Future<void> notifyPickupOtp({
    required String idToken,
    required String bookingId,
  }) async {
    await http
        .post(
          _u('/api/notify/booking-otp'),
          headers: _auth(idToken),
          body: jsonEncode({'bookingId': bookingId}),
        )
        .timeout(const Duration(seconds: 15));
  }

  static Future<String> rideAction({
    required String idToken,
    required bool start,
    String? bookingId,
  }) async {
    final r = await http
        .post(
          _u(start ? '/api/rides/rider-start' : '/api/rides/rider-end'),
          headers: _auth(idToken),
          body: jsonEncode({
            'firebaseIdToken': idToken,
            if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final j = _json(r);
    if (j['success'] != true) {
      throw ApiException(_message(j, 'Unable to update ride.'));
    }
    return j['message']?.toString() ??
        (start
            ? 'Ride started. Pay any remaining amount before you return.'
            : 'Ride end OTP is ready. Tell this to the yard to return the scooter.');
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
  static const daily = 250;
  static const weekly = 1750;
  static const monthly = 7500;
  static const rtoDaily = 300;
  static const rtoMonths = 20;
  static const securityDeposit = 2500;
  static const gstNote = 'GST included on rental';
  static const partnerShare = 0.60;
  static const partnerMonths = 42;
  static const scootersPerLakh = 3;
  /// Scaled from the prior ₹52.2 / scooter / day at ₹230 rent.
  static const investorPerScooterDay = 57;

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

  static int investorMonthly(int lakhs) =>
      investorPerScooterDay * scootersPerLakh * lakhs * 30;

  static int investorTerm(int lakhs) => investorMonthly(lakhs) * partnerMonths;

  static int scrapValue(int lakhs) => 18000 * lakhs;

  static Map<String, dynamic> payload() => {
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
    this.message = '',
  });

  factory RiderBooking.fromJson(Map e) {
    final nested = e['data'];
    final m = nested is Map ? nested : e;
    return RiderBooking(
      mongoId: m['_id']?.toString() ?? e['bookingMongoId']?.toString() ?? '',
      bookingId: m['bookingId']?.toString() ?? e['bookingId']?.toString() ?? '',
      rentalMode: m['rentalMode']?.toString() ?? '',
      paymentStatus: (m['paymentStatus'] ?? e['paymentStatus'])?.toString() ?? '',
      rideStatus: (m['rideStatus'] ?? e['rideStatus'])?.toString() ?? '',
      pendingAmount: _asDouble(m['pendingAmount'] ?? e['pendingAmount']) ?? 0,
      receivedAmount: _asDouble(m['receivedAmount'] ?? e['receivedAmount'] ?? e['paidAmount']) ?? 0,
      paymentDue: _asDouble(m['paymentDue'] ?? e['paymentDue']) ?? 0,
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
  final String message;

  double get due => pendingAmount > 0.009
      ? pendingAmount
      : (paymentDue > 0.009 ? paymentDue : 0);

  bool get hasPickupOtp => pickupOtp.isNotEmpty;
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
    return RazorpayOrder(
      keyId: e['keyId']?.toString() ?? e['key']?.toString() ?? '',
      orderId: e['orderId']?.toString() ?? e['id']?.toString() ?? '',
      amount: _asDouble(e['amount']) ?? 0,
      currency: e['currency']?.toString() ?? 'INR',
      name: e['name']?.toString() ?? 'EVUDDY',
      image: e['image']?.toString(),
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

class RiderLookup {
  const RiderLookup({
    required this.found,
    this.riderId,
    this.approvalStatus = '',
    this.bookingEnabled = false,
    this.message,
  });
  const RiderLookup.missing() : this(found: false);

  final bool found;
  final String? riderId;
  final String approvalStatus;
  final bool bookingEnabled;
  final String? message;
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
  });

  final bool ok;
  final int statusCode;
  final String? message;
  final List<String> errors;
  final bool riderExists;
  final String? riderId;
  final String? riderStatus;
}
