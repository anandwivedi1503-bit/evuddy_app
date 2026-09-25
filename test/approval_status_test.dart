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
}
