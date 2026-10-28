/// Maps exceptions to short rider-safe copy (no stack traces on screen).
String userFacingError(Object error, {String fallback = 'Something went wrong. Try again.'}) {
  final raw = error.toString();
  if (raw.contains('PlatformException') &&
      (raw.contains('flutter_local_notifications') ||
          raw.contains('Missing type parameter'))) {
    return 'Trip reminders could not be saved on this phone. The in-app timer and alerts still work.';
  }
  if (raw.contains('ApiException:')) {
    return raw.replaceFirst('ApiException: ', '').trim();
  }
  if (raw.contains('Razorpay') || raw.contains('payment')) {
    return 'Payment could not finish. Check UPI or card and try again.';
  }
  if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
    return 'No connection to evuddy.com. Check mobile data or Wi‑Fi.';
  }
  if (raw.length > 160) return fallback;
  return raw;
}
