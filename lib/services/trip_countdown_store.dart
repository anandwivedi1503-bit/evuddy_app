import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rider-only trip end countdown (shown as siren banner + Alerts).
class TripCountdownStore {
  TripCountdownStore._();
  static final TripCountdownStore instance = TripCountdownStore._();

  static const _key = 'evuddy_trip_countdown_v1';
  final ValueNotifier<int> tick = ValueNotifier(0);

  String bookingId = '';
  String durationLabel = '';
  DateTime? tripEndsAt;
  DateTime? reminderAt;

  bool get active => bookingId.isNotEmpty && tripEndsAt != null;

  bool get overdue =>
      tripEndsAt != null && !tripEndsAt!.isAfter(DateTime.now());

  Duration? get timeUntilEnd {
    if (tripEndsAt == null) return null;
    final d = tripEndsAt!.difference(DateTime.now());
    return d;
  }

  Duration? get timeUntilReminder {
    if (reminderAt == null) return null;
    final d = reminderAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      final m = jsonDecode(raw);
      if (m is! Map) return;
      bookingId = m['bookingId']?.toString() ?? '';
      durationLabel = m['durationLabel']?.toString() ?? '';
      tripEndsAt = DateTime.tryParse(m['tripEndsAt']?.toString() ?? '');
      reminderAt = DateTime.tryParse(m['reminderAt']?.toString() ?? '');
      _pulse();
    } catch (_) {}
  }

  Future<void> schedule({
    required String bookingId,
    required String durationLabel,
    required DateTime tripEndsAt,
    DateTime? reminderAt,
  }) async {
    this.bookingId = bookingId;
    this.durationLabel = durationLabel;
    this.tripEndsAt = tripEndsAt;
    this.reminderAt = reminderAt;
    await _persist();
    _pulse();
  }

  Future<void> clear() async {
    bookingId = '';
    durationLabel = '';
    tripEndsAt = null;
    reminderAt = null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key);
    } catch (_) {}
    _pulse();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'bookingId': bookingId,
          'durationLabel': durationLabel,
          'tripEndsAt': tripEndsAt?.toIso8601String(),
          'reminderAt': reminderAt?.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  void _pulse() => tick.value++;

  static String formatDuration(Duration d) {
    final seconds = d.inSeconds.abs();
    final h = seconds ~/ 3600;
    final m = (seconds ~/ 60).remainder(60);
    final s = seconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
