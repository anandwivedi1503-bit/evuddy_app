import 'booking_end_schedule.dart';
import 'trip_countdown_store.dart';
import '../api/evuddy_api.dart';
import '../state/registration_draft.dart';

/// Keeps the siren timer in sync after app restart and server booking refresh.
class TripCountdownSync {
  TripCountdownSync._();

  static void apply(RiderBooking? booking) {
    if (booking == null || booking.bookingId.isEmpty) {
      return;
    }
    if (booking.completed || booking.cancelled) {
      if (TripCountdownStore.instance.bookingId == booking.bookingId) {
        TripCountdownStore.instance.clear();
      }
      return;
    }

    final end = booking.rentalEndDate;
    if (end != null && end.isAfter(DateTime.now())) {
      _scheduleIfNeeded(
        bookingId: booking.bookingId,
        duration: _durationLabel(booking),
        units: registrationDraft.rentalUnits,
        tripEndsAt: end,
      );
      return;
    }

    final live = booking.isOpenRide || booking.inRide || booking.hasPickupOtp;
    if (!live) return;

    final duration = registrationDraft.chosenDuration ??
        (booking.rentalMode.isNotEmpty ? booking.rentalMode : 'Daily');
    if (duration == 'Rent To Own') return;
    final units = registrationDraft.rentalUnits.clamp(1, BookingEndSchedule.maxUnits(duration));
    final computed = BookingEndSchedule.rentalEndsAt(
      duration: duration,
      units: units,
      from: DateTime.now(),
    );
    if (computed == null) return;
    _scheduleIfNeeded(
      bookingId: booking.bookingId,
      duration: duration,
      units: units,
      tripEndsAt: computed,
    );
  }

  static String _durationLabel(RiderBooking booking) {
    final d = registrationDraft.chosenDuration ?? booking.rentalMode;
    final u = registrationDraft.rentalUnits;
    if (d.isEmpty) return booking.bookingId;
    return '$d · $u ${BookingEndSchedule.unitLabel(d)}';
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
      durationLabel: '$duration · $units ${BookingEndSchedule.unitLabel(duration)}',
      tripEndsAt: tripEndsAt,
      reminderAt: remind ?? tripEndsAt.subtract(const Duration(hours: 1)),
    );
