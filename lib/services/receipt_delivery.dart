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
        ? 'Payment saved. Receipt email + SMS go to your profile email and registered mobile when evuddy.com is updated.'
        : 'Receipt sent via ${channels.join(' & ')} (email + registered mobile SMS when enabled on server).';
    await SecurityAlertHub.instance.push(
      title: 'Payment receipt',
      body: summary,
      category: 'payment',
    );
    return summary;
  }
}
