import '../api/evuddy_api.dart';
import 'security_alert_hub.dart';

class ReceiptDelivery {
  const ReceiptDelivery._();

  static Future<String> sendAfterPayment({
    required String idToken,
    required RiderBooking booking,
    required String email,
    required String phone,
    double? amountRupees,
  }) async {
    final channels = <String>[];
    try {
      final result = await EvuddyApi.deliverPaymentReceipt(
        idToken: idToken,
        bookingId: booking.bookingId,
        bookingMongoId: booking.mongoId,
        email: email,
        phone: phone,
        amountRupees: amountRupees ?? booking.receivedAmount,
      );
      channels.addAll(result.channels);
    } catch (_) {}
    final summary = channels.isEmpty
        ? 'Payment saved. Receipt will appear under Ride history when the server sends it.'
        : 'Receipt sent via ${channels.join(' & ')}.';
    await SecurityAlertHub.instance.push(
      title: 'Payment receipt',
      body: summary,
      category: 'payment',
    );
    return summary;
  }
}
