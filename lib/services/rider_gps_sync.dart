import 'dart:async';

import '../api/evuddy_api.dart';
import '../state/registration_draft.dart';
import 'rider_safety_tracker.dart';
import 'trip_countdown_sync.dart';

/// Keeps phone GPS uplink on whenever the server says the trip is live (not only after one screen action).
class RiderGpsSync {
  RiderGpsSync._();

  static void schedule(RiderBooking? booking) {
    unawaited(apply(booking));
  }

  static Future<void> apply(RiderBooking? booking) async {
    if (!registrationDraft.phoneVerified) {
      await RiderSafetyTracker.instance.stop();
      return;
    }
    if (booking == null ||
        booking.bookingId.isEmpty ||
        booking.completed ||
        booking.cancelled) {
      await RiderSafetyTracker.instance.stop();
      return;
    }

    final track = TripCountdownSync.rideClockOpen(booking);
    if (!track) {
      await RiderSafetyTracker.instance.stop();
      return;
    }

    final token = await registrationDraft.freshToken(force: false);
    if (token == null || token.isEmpty) return;

    await RiderSafetyTracker.instance.start(
      bookingId: booking.bookingId,
      idToken: token,
    );
  }
}
