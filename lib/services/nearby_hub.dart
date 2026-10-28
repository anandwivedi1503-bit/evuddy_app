import 'dart:math';

import '../api/evuddy_api.dart';

/// Pick nearest hub/city from phone GPS (Rapido-style default hub).
class NearbyHub {
  NearbyHub._();

  static double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  static ({EvuddyHub? hub, String? city}) nearest({
    required List<EvuddyHub> hubs,
    required double latitude,
    required double longitude,
  }) {
    EvuddyHub? best;
    var bestKm = double.infinity;
    for (final h in hubs) {
      final lat = h.latitude;
      final lng = h.longitude;
      if (lat == null || lng == null) continue;
      final km = _distanceKm(latitude, longitude, lat, lng);
      if (km < bestKm) {
        bestKm = km;
        best = h;
      }
    }
    if (best == null) return (hub: null, city: null);
    return (hub: best, city: best.city);
  }
}
