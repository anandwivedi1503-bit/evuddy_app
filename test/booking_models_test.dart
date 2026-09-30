import 'package:evuddy_app/api/evuddy_api.dart';
import 'package:evuddy_app/api/partner_pdf.dart';
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
        'pickupOtp': '4821',
        'rideEndOtp': '7732',
        'paymentStatus': 'Partial',
      },
    });
    expect(booking.mongoId, 'mongo1');
    expect(booking.bookingId, 'BK-9');
    expect(booking.hasPickupOtp, isTrue);
    expect(booking.pickupOtp, '4821');
    expect(booking.rideEndOtp, '7732');
    expect(booking.due, 241.5);
    expect(booking.message, contains('Payment successful'));
    expect(
      RiderBooking.fromJson({
        'pickupOTP': '1111',
        'rideEndOTP': '2222',
      }).rideEndOtp,
      '2222',
    );
    expect(
      RiderBooking.fromJson({
        'success': true,
        'remainingAmount': 249,
        'receivedAmount': 1,
        'booking': {
          'id': 'mongo2',
          'bookingId': 'BK-10',
          'pickupOTP': '5555',
          'paymentStatus': 'Partial',
        },
      }).due,
      249,
    );
    expect(
      RiderBooking.fromJson({
        'data': {
          '_id': 'mongo3',
          'receivedAmount': 1,
          'paymentDue': 250,
          'pickupOTP': '9001',
        },
      }).due,
      249,
    );
    expect(
      RiderBooking.fromJson({
        'receivedAmount': 1,
        'pendingAmount': 249,
      }).isRemainingPayment,
      isTrue,
    );
    final verified = RiderBooking.fromJson({
      'receivedAmount': 250,
      'pendingAmount': 0,
      'pickupOTP': '1111',
      'rideEndOTP': '9999',
    });
    final staleMine = RiderBooking.fromJson({
      'receivedAmount': 1,
      'pendingAmount': 249,
      'pickupOTP': '1111',
    });
    final merged = verified.mergedWith(staleMine);
    expect(merged.receivedAmount, 250);
    expect(merged.due, 0);
    expect(merged.rideEndOtp, '9999');
    expect(
      RiderBooking.fromJson({
        'pickupOTPVerified': true,
        'rideStatus': 'Ready For Pickup',
        'rentalMode': 'Daily',
      }).inRide,
      isFalse,
    );
    expect(
      RiderBooking.fromJson({
        'pickupOTPVerified': true,
        'rideStatus': 'Ready For Pickup',
      }).readyForPickup,
      isTrue,
    );
    expect(
      RiderBooking.fromJson({
        'rideStatus': 'In Ride',
        'rentalMode': 'Rent To Own',
      }).isRentToOwn,
      isTrue,
    );
    expect(
      RiderBooking.fromJson({
        'rideStatus': 'In Ride',
      }).inRide,
      isTrue,
    );
  });

  test('sniffs jpeg/png/webp and rejects mismatch names', () {
    expect(sniffImageBytes([0xFF, 0xD8, 0xFF, ...List.filled(12, 0)]).extension, 'jpg');
    expect(
      sniffImageBytes([0x89, 0x50, 0x4E, 0x47, ...List.filled(12, 0)]).extension,
      'png',
    );
    expect(
      sniffImageBytes([
        0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50,
      ]).extension,
      'webp',
    );
    expect(
      () => sniffImageBytes(List.filled(20, 0)),
      throwsA(isA<ApiException>()),
    );
  });

  test('catalog rates and Indian rupee format', () {
    expect(CatalogRates.hourly, 60);
    expect(CatalogRates.daily, 250);
    expect(CatalogRates.weekly, 1750);
    expect(CatalogRates.monthly, 7500);
    expect(CatalogRates.rtoDaily, 300);
    expect(CatalogRates.rtoMonths, 20);
    expect(CatalogRates.securityDeposit, 2500);
    expect(CatalogRates.inr(60), '₹60');
    expect(CatalogRates.inr(250), '₹250');
    expect(CatalogRates.inr(1750), '₹1,750');
    expect(CatalogRates.inr(7500), '₹7,500');
    expect(CatalogRates.lowSpeedMonthly(5), 15000);
    expect(CatalogRates.highSpeedMonthly(5), 18000);
    expect(FleetPartner.low.invest(5), 300000);
    expect(FleetPartner.high.invest(5), 450000);
    expect(CatalogRates.amountForDuration('Hourly'), 60);
    expect(CatalogRates.amountForDuration('Daily'), 250);
    expect(CatalogRates.payload()['hourly'], 60);
    expect(CatalogRates.payload()['daily'], 250);
    expect(RazorpayOrder.fromJson({
      'keyId': 'rzp',
      'orderId': 'order_1',
      'amount': 250000,
      'currency': 'INR',
    }).amountPaise(2500), 250000);
    expect(RazorpayOrder.fromJson({
      'keyId': 'rzp',
      'orderId': 'order_1',
      'amount': 2500,
      'currency': 'INR',
    }).amountPaise(2500), 250000);
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
    expect(
      RazorpayOrder.fromJson({
        'success': true,
        'data': {
          'keyId': 'rzp_live_nested',
          'orderId': 'order_nested',
          'amount': 100,
          'name': 'Shubhrax Mobility Limited',
        },
      }).name,
      'Shubhrax Mobility Limited',
    );
    expect(
      RazorpayOrder.fromJson({
        'keyId': 'rzp',
        'orderId': 'order_1',
        'amount': 100,
      }).name,
      'Shubhrax Mobility Limited',
    );
  });

  test('parses support tickets from website payloads', () {
    final ticket = SupportTicket.fromJson({
      'ticketId': 'BK-1',
      'bookingId': 'EVB-9',
      'category': 'UNLOCK_ISSUE',
      'status': 'OPEN',
      'description': 'Pickup OTP not working at the yard.',
      'adminRemarks': 'Hub called the rider',
    });
    expect(ticket.ticketId, 'BK-1');
    expect(ticket.bookingId, 'EVB-9');
    expect(ticket.category, 'UNLOCK_ISSUE');
    expect(ticket.status, 'OPEN');
    expect(ticket.adminRemarks, contains('Hub'));
  });
}
