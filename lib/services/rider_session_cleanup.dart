import 'rider_notifications.dart';
import 'rider_safety_tracker.dart';
import 'security_alert_hub.dart';
import 'trip_countdown_store.dart';
import '../state/registration_draft.dart';

/// Clears on-device trip UI when the rider logs out (server booking stays on evuddy.com).
Future<void> clearRiderLocalTripState({String? bookingIdForNotifications}) async {
  final id = bookingIdForNotifications ??
      registrationDraft.activeBooking?.bookingId ??
      TripCountdownStore.instance.bookingId;
  if (id.isNotEmpty) {
    await RiderNotifications.instance.cancelForBooking(id);
  }
  await RiderSafetyTracker.instance.stop();
  await TripCountdownStore.instance.clear();
  await SecurityAlertHub.instance.clearAll();
}
