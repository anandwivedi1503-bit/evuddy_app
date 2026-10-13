import 'package:evuddy_app/api/evuddy_api.dart';
import 'package:evuddy_app/state/registration_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('treats website approval spellings as bookable', () {
    expect(RiderLookup.isApprovedStatus('Approved'), isTrue);
    expect(RiderLookup.isApprovedStatus('approved'), isTrue);
    expect(RiderLookup.isApprovedStatus('APPROVED'), isTrue);
    expect(RiderLookup.isApprovedStatus('Active'), isTrue);
    expect(RiderLookup.isApprovedStatus('Under Review'), isFalse);
    expect(RiderLookup.isApprovedStatus('Rejected'), isFalse);
    expect(RiderLookup.isRejectedStatus('Rejected'), isTrue);
    expect(RiderLookup.isPendingStatus('Under Review'), isTrue);
  });

  test('parses nested and flat rider lookup payloads', () {
    final nested = RiderLookup.fromData({
      'riderId': 'R-1',
      'approvalStatus': 'Approved',
      'bookingEnabled': false,
      'fullName': 'Asha',
    });
    expect(nested.found, isTrue);
    expect(nested.bookingEnabled, isTrue);
    expect(nested.riderId, 'R-1');

    final flat = RiderLookup.fromData({
      'id': 'abc',
      'status': 'under_review',
      'canBook': false,
    });
    expect(flat.bookingEnabled, isFalse);
    expect(RiderLookup.isPendingStatus(flat.approvalStatus), isTrue);

    final enabled = RiderLookup.fromData({
      'riderId': 'R-2',
      'kycStatus': 'pending',
      'bookingEnabled': true,
    });
    expect(enabled.bookingEnabled, isTrue);
  });

  test('draft canBook follows approval or bookingEnabled', () {
    final d = RegistrationDraft()
      ..phoneVerified = true
      ..approvalStatus = 'Under Review'
      ..bookingEnabled = false;
    expect(d.canBook, isFalse);
    expect(d.isPendingKyc, isFalse);
    d.riderId = 'R-9';
    expect(d.isPendingKyc, isTrue);
    d.approvalStatus = 'Approved';
    expect(d.canBook, isTrue);
    d.approvalStatus = '';
    d.bookingEnabled = true;
    expect(d.canBook, isTrue);
  });

  test('live website booking locks plan and skips plan pick', () {
    final d = RegistrationDraft()
      ..phoneVerified = true
      ..approvalStatus = 'Approved';
    expect(d.hasLiveBooking, isFalse);
    d.applyActiveBooking(
      RiderBooking.fromJson({
        'bookingId': 'BK-22',
        'rentalMode': 'Daily',
        'pendingAmount': 2737,
        'receivedAmount': 13,
        'pickupOTP': '4821',
        'rideStatus': 'Ready For Pickup',
      }),
    );
    expect(d.hasLiveBooking, isTrue);
    expect(d.chosenPlan, 'rental');
    expect(d.chosenDuration, 'Daily');
    d.applyActiveBooking(
      RiderBooking.fromJson({
        'bookingId': 'RTO-1',
        'rentalMode': 'Rent To Own',
        'pendingAmount': 2800,
      }),
    );
    expect(d.chosenPlan, 'rto');
    d.applyActiveBooking(null);
    expect(d.hasLiveBooking, isFalse);
    d.activeBooking = const RiderBooking(bookingId: 'STALE');
    expect(d.hasLiveBooking, isFalse);
  });
}
