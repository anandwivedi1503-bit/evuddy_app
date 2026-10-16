import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'evuddy_api.dart';

/// Official `Razorpay.open` — same CheckoutActivity that captured the first ₹1
/// on GPay / PhonePe. Remaining due uses this, not a WebView toast.
class InAppRazorpay {
  InAppRazorpay._();

  static Map<String, dynamic> optionsFor({
    required RazorpayOrder order,
    required double rupees,
    required String bookingId,
    required String contact,
    required String customerName,
    String email = '',
    String? vehicleId,
  }) {
    final digits = contact.replaceAll(RegExp(r'\D'), '');
    final contact10 =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    final name = order.name.trim().isEmpty ? 'EVUDDY' : order.name.trim();
    final image = (order.image ?? '').trim().isEmpty
        ? 'https://www.evuddy.com/Evuddy-logo-dark-E.png'
        : order.image!.trim();
    return {
      'key': order.keyId,
      'amount': order.amountPaise(rupees),
      'currency': order.currency.isEmpty ? 'INR' : order.currency,
      'name': name,
      'image': image,
      'description': 'Booking Payment - $bookingId',
      'order_id': order.orderId,
      'prefill': {
        'name': customerName.isEmpty ? 'Rider' : customerName,
        'contact': contact10,
        if (email.contains('@')) 'email': email,
      },
      'notes': {
        'bookingId': bookingId,
        if (vehicleId != null && vehicleId.isNotEmpty) 'vehicleId': vehicleId,
      },
      'theme': {'color': '#18B368'},
      'retry': {'enabled': true, 'max_count': 4},
    };
  }

  static Future<Map<String, String>?> open({
    required RazorpayOrder order,
    required double rupees,
    required String bookingId,
    required String contact,
    required String customerName,
    String email = '',
    String? vehicleId,
  }) async {
    if (kIsWeb) return null;
    if (order.keyId.isEmpty || order.orderId.isEmpty) return null;

    final options = optionsFor(
      order: order,
      rupees: rupees,
      bookingId: bookingId,
      contact: contact,
      customerName: customerName,
      email: email,
      vehicleId: vehicleId,
    );

    final done = Completer<Map<String, String>?>();
    final sdk = Razorpay();

    void finish(Map<String, String>? value) {
      if (!done.isCompleted) done.complete(value);
      try {
        sdk.clear();
      } catch (_) {}
    }

    sdk.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse res) {
      finish({
        'orderId': (res.orderId == null || res.orderId!.isEmpty)
            ? order.orderId
            : res.orderId!,
        'paymentId': res.paymentId ?? '',
        'signature': res.signature ?? '',
      });
    });
    sdk.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse res) {
      final msg = (res.message ?? '').toLowerCase();
      final cancelled = res.code == Razorpay.PAYMENT_CANCELLED ||
          msg.contains('cancel') ||
          msg.contains('dismiss') ||
          msg.contains('back pressed');
      finish(cancelled ? const {'cancelled': 'true'} : null);
    });
    sdk.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse res) {});

    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      sdk.open(Map<String, dynamic>.from(options));
    } catch (_) {
      finish(null);
      return null;
    }

    return done.future.timeout(
      const Duration(minutes: 8),
      onTimeout: () {
        try {
          sdk.clear();
        } catch (_) {}
        return null;
      },
    );
  }
}
