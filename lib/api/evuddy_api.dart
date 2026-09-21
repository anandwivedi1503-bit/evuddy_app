import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
  }) async {
    final req = http.MultipartRequest('POST', _u('/api/upload'))
      ..fields['firebaseIdToken'] = idToken
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send().timeout(const Duration(seconds: 45));
    final r = await http.Response.fromStream(streamed);
    final j = _json(r);
    final url = j['url']?.toString();
    if (j['success'] == true && url != null && url.isNotEmpty) return url;
    throw ApiException(j['error']?.toString() ?? j['message']?.toString() ?? 'File upload failed.');
  }

  static Future<RegisterResult> createRider(Map<String, dynamic> body) async {
    final r = await http
        .post(
          _u('/api/riders'),
          headers: {'Content-Type': 'application/json'},
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
        .map(
          (e) => EvuddyHub(
            id: e['_id']?.toString() ?? '',
            name: e['hubName']?.toString() ?? '',
            code: e['hubCode']?.toString() ?? '',
            location: e['hubLocation']?.toString() ?? '',
            city: e['city']?.toString() ?? '',
          ),
        )
        .where((h) => h.name.isNotEmpty)
        .toList();
  }
}

/// Public fare card on the website landing / Book EV catalog.
class CatalogRates {
  static const hourly = 60;
  static const daily = 230;
  static const weekly = 1610;
  static const monthly = 6900;
  static const rtoDaily = 280;
  static const rtoMonths = 18;
  static const gstNote = 'GST 5% on rent only';
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
  });
  final String id;
  final String name;
  final String code;
  final String location;
  final String city;
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
