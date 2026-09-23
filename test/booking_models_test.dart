import 'package:evuddy_app/api/evuddy_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live hub JSON and prefers India maps query', () {
    final hub = EvuddyHub.fromJson({
      '_id': '6a7da2d09d0149c9a7628688',
      'hubName': 'Luck',
      'hubCode': '01',
      'hubLocation': 'Takrohi',
      'city': 'Lucknow',
      'latitude': 5.2,
      'longitude': 3.8,
    });
    expect(hub.name, 'Luck');
    expect(hub.mapsQuery, 'Luck, Takrohi, Lucknow');
    final india = EvuddyHub.fromJson({
      'hubName': 'Gomti',
      'hubLocation': 'Hazratganj',
      'city': 'Lucknow',
      'latitude': 26.8467,
      'longitude': 80.9462,
    });
    expect(india.mapsQuery, '26.8467,80.9462');
  });

  test('parses vehicle and booking JSON from website payloads', () {
    final v = EvuddyVehicle.fromJson({
      '_id': 'veh1',
      'vehicleId': 'EV-01',
      'registrationNumber': 'UP32AB1234',
      'vehicleModel': 'EVUDDY Electric Scooter',
      'currentHub': '01',
      'batteryPercentage': '88',
    });
    expect(v.vehicleId, 'EV-01');
    expect(v.batteryPercentage, 88);

    final booking = RiderBooking.fromJson({
      'success': true,
      'message': 'Payment successful. Booking confirmed.',
      'data': {
        '_id': 'mongo1',
        'bookingId': 'BK-9',
        'pendingAmount': 241.5,
        'receivedAmount': 1,
        'pickupOTP': '4821',
        'paymentStatus': 'Partial',
      },
    });
    expect(booking.mongoId, 'mongo1');
    expect(booking.bookingId, 'BK-9');
    expect(booking.hasPickupOtp, isTrue);
    expect(booking.due, 241.5);
    expect(booking.message, contains('Payment successful'));
  });

  test('catalog rates and Indian rupee format', () {
    expect(CatalogRates.daily, 250);
    expect(CatalogRates.weekly, 1750);
    expect(CatalogRates.monthly, 7500);
    expect(CatalogRates.rtoDaily, 300);
    expect(CatalogRates.rtoMonths, 20);
    expect(CatalogRates.securityDeposit, 2500);
    expect(CatalogRates.inr(250), '₹250');
    expect(CatalogRates.inr(1750), '₹1,750');
    expect(CatalogRates.inr(7500), '₹7,500');
    expect(CatalogRates.investorMonthly(1), 5130);
  });

  test('parses Razorpay create-order response', () {
    final order = RazorpayOrder.fromJson({
      'success': true,
      'keyId': 'rzp_live_test',
      'orderId': 'order_123',
      'amount': 100,
      'currency': 'INR',
      'name': 'EVUDDY',
    });
    expect(order.keyId, 'rzp_live_test');
    expect(order.orderId, 'order_123');
    expect(order.amount, 100);
  });
}
