import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../api/evuddy_api.dart';
import 'booking_end_schedule.dart';
import 'security_alert_hub.dart';
import 'trip_countdown_store.dart';

/// Local + server nudges one hour before rental ends.
class RiderNotifications {
  RiderNotifications._();
  static final RiderNotifications instance = RiderNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (_) {},
    );
    const channel = AndroidNotificationChannel(
      'evuddy_trip_alerts',
      'Trip & security alerts',
      description: 'Booking end reminders and EVUDDY safety messages',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _ready = true;
  }

  Future<void> requestPermissionIfNeeded() async {
    if (kIsWeb) return;
    await Permission.notification.request();
  }

  Future<void> scheduleRentalEndReminder({
    required String bookingId,
    required String duration,
    required int units,
    required String phone,
    String? idToken,
    DateTime? rideStartedAt,
  }) async {
    await ensureReady();
    await requestPermissionIfNeeded();
    final end = BookingEndSchedule.rentalEndsAt(
      duration: duration,
      units: units,
      from: rideStartedAt ?? DateTime.now(),
    );
    if (end == null || bookingId.isEmpty) return;
    final remind = BookingEndSchedule.reminderOneHourBefore(end);
    final title = 'EVUDDY · booking ending soon';
    final body = BookingEndSchedule.humanEnd(duration, units, end);
    await SecurityAlertHub.instance.push(
      title: title,
      body: body,
      category: 'reminder',
      security: true,
    );
    if (remind == null) {
      await _plugin.show(
        bookingId.hashCode,
        title,
        body,
        _details(),
      );
    } else {
      try {
        await _plugin.zonedSchedule(
          bookingId.hashCode,
          title,
          body,
          tz.TZDateTime.from(remind, tz.local),
          _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('EVUDDY zonedSchedule failed: $e');
        await _plugin.show(
          bookingId.hashCode,
          title,
          body,
          _details(),
        );
      }
    }
    await TripCountdownStore.instance.schedule(
      bookingId: bookingId,
      durationLabel: '$duration · $units ${BookingEndSchedule.unitLabel(duration)}',
      tripEndsAt: end,
      reminderAt: remind ?? end.subtract(const Duration(hours: 1)),
    );
    if (idToken != null && idToken.isNotEmpty && phone.isNotEmpty) {
      try {
        await EvuddyApi.notifyRentalReminder(
          idToken: idToken,
          bookingId: bookingId,
          phone: phone,
          endsAtIso: end.toUtc().toIso8601String(),
          duration: duration,
          units: units,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelForBooking(String bookingId) async {
    if (bookingId.isEmpty) return;
    await _plugin.cancel(bookingId.hashCode);
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'evuddy_trip_alerts',
          'Trip & security alerts',
          channelDescription: 'Booking end reminders and EVUDDY safety messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
}
