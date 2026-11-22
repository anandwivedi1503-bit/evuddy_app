import 'dart:async';

import 'booking_end_schedule.dart';
import 'trip_countdown_store.dart';
import '../api/evuddy_api.dart';
import '../state/registration_draft.dart';

/// Keeps the siren timer in sync after app restart and server booking refresh.
class TripCountdownSync {
  TripCountdownSync._();

  static void apply(RiderBooking? booking) {
    if (!registrationDraft.phoneVerified) {
      unawaited(TripCountdownStore.instance.clear());
      return;
    }
    if (booking == null || booking.bookingId.isEmpty) {
      return;
    }
    if (booking.completed || booking.cancelled) {
      if (TripCountdownStore.instance.bookingId == booking.bookingId) {
        unawaited(TripCountdownStore.instance.clear());
      }
      return;
    }

    if (!booking.inRide) {
      if (TripCountdownStore.instance.bookingId == booking.bookingId) {
        unawaited(TripCountdownStore.instance.clear());
      }
      return;
    }

    if (booking.isRentToOwn) return;
    final end = booking.rentalEndDate;
    if (end != null) {
      _scheduleIfNeeded(
        bookingId: booking.bookingId,
        duration: _durationLabel(booking),
        units: _unitsFor(booking),
        tripEndsAt: end,
      );
      return;
    }
    if (TripCountdownStore.instance.bookingId != booking.bookingId) {
      unawaited(TripCountdownStore.instance.clear());
    }
  }

  static String _durationLabel(RiderBooking booking) {
    final d = booking.rentalMode.isNotEmpty
        ? booking.rentalMode
        : (registrationDraft.chosenDuration ?? 'Daily');
    final u = _unitsFor(booking);
    if (d.isEmpty) return booking.bookingId;
    return '$d · $u ${BookingEndSchedule.unitLabel(d)}';
  }

  static int _unitsFor(RiderBooking booking) {
    final duration = booking.rentalMode.isNotEmpty
        ? booking.rentalMode
        : (registrationDraft.chosenDuration ?? 'Daily');
    final units = duration == 'Hourly'
        ? booking.rentalHours
        : registrationDraft.rentalUnits;
    return units.clamp(1, BookingEndSchedule.maxUnits(duration)).toInt();
  }

  static void _scheduleIfNeeded({
    required String bookingId,
    required String duration,
    required int units,
    required DateTime tripEndsAt,
  }) {
    final store = TripCountdownStore.instance;
    if (store.bookingId == bookingId &&
        store.tripEndsAt != null &&
        (store.tripEndsAt!.difference(tripEndsAt).inMinutes).abs() < 2 &&
        store.active) {
      store.tick.value++;
      return;
    }
    final remind = BookingEndSchedule.reminderOneHourBefore(tripEndsAt);
    store.schedule(
      bookingId: bookingId,
      durationLabel:
          '$duration · $units ${BookingEndSchedule.unitLabel(duration)}',
      tripEndsAt: tripEndsAt,
      reminderAt: remind ?? tripEndsAt.subtract(const Duration(hours: 1)),
    );
  }
}
