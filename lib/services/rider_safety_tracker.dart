import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/evuddy_api.dart';
import 'security_alert_hub.dart';

/// Phone GPS uplink while a ride is active (IoT backup until fleet GPS is live).
class RiderSafetyTracker {
  RiderSafetyTracker._();
  static final RiderSafetyTracker instance = RiderSafetyTracker._();

  StreamSubscription<Position>? _sub;
  String? _bookingId;
  String? _idToken;
  DateTime? _lastUpload;

  bool get active => _sub != null;

  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      await SecurityAlertHub.instance.push(
        title: 'Turn on location for safety',
        body: 'EVUDDY uses your phone GPS only during an active ride — same idea as Rapido trip safety.',
        category: 'safety',
        security: true,
      );
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      await Permission.locationWhenInUse.request();
      return false;
    }
    return true;
  }

  Future<void> start({
    required String bookingId,
    required String idToken,
  }) async {
    if (bookingId.isEmpty || idToken.isEmpty) return;
    await stop();
    final ok = await ensurePermission();
    if (!ok) return;
    _bookingId = bookingId;
    _idToken = idToken;
    await SecurityAlertHub.instance.push(
      title: 'Safety GPS is on',
      body: 'Your live phone location is shared with EVUDDY ops during this ride. Fleet IoT will join when installed.',
      category: 'safety',
      security: true,
    );
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 35,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(_onPosition);
  }

  Future<void> _onPosition(Position pos) async {
    final token = _idToken;
    final bookingId = _bookingId;
    if (token == null || bookingId == null) return;
    final now = DateTime.now();
    if (_lastUpload != null && now.difference(_lastUpload!) < const Duration(seconds: 45)) {
      return;
    }
    _lastUpload = now;
    try {
      await EvuddyApi.postRiderSafetyLocation(
        idToken: token,
        bookingId: bookingId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
      );
    } catch (_) {}
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _bookingId = null;
    _idToken = null;
    _lastUpload = null;
  }
}
