import '../api/evuddy_api.dart';
import 'security_alert_hub.dart';

class ReceiptDelivery {
  const ReceiptDelivery._();

  static Future<String> sendAfterPayment({
    required RiderBooking booking,
    double? amountRupees,
  }) async {
    final amount = amountRupees ?? booking.receivedAmount;
    final summary =
        'Payment of ₹${amount.round()} saved. The PDF receipt is available in Account → Rides & Receipts. Payment messages are sent by the server when the rider contact and delivery service are configured.';
    await SecurityAlertHub.instance.push(
      title: 'Payment receipt',
      body: summary,
      category: 'payment',
    );
    return summary;
  }
}
