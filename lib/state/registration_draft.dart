import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/evuddy_api.dart';
import '../api/firebase_phone.dart';

class RegistrationDraft {
  String phone = '';
  bool phoneVerified = false;
  String? firebaseUid;
  String? firebaseIdToken;
  String? firebaseRefreshToken;
  String? verificationId;

  String fullName = '';
  String email = '';
  String comingThrough = 'Direct / EVUDDY';

  String aadhaar = '';
  String drivingLicense = '';
  String instagramId = '';
  String facebookId = '';
  String reference1Name = '';
  String reference1Phone = '';
  String reference2Name = '';
  String reference2Phone = '';

  String? aadhaarFrontPath;
  String? aadhaarBackPath;
  String? licenseFrontPath;
  String? licenseBackPath;
  String? profilePhotoPath;

  String? riderId;
  String approvalStatus = '';
  bool bookingEnabled = false;
  bool apiOnline = false;
  String? chosenPlan;
  String? chosenCity;
  String? chosenHubId;
  String? chosenDuration;
  RiderBooking? activeBooking;
  String otpGate = 'register'; // register | book
  int shellTab = 0;
  int? _tabJump;
  double depositHeld = 0;
  String depositStatus = 'none'; // none | held | refund_pending | released
  String? depositBookingId;

  String get depositLabel {
    switch (depositStatus) {
      case 'held':
        return 'Held · Rent to Own';
      case 'refund_pending':
        return 'Scooter back · refund queued';
      case 'released':
        return 'Released';
      default:
        return 'No hold';
    }
  }

  bool get isApproved =>
      bookingEnabled || RiderLookup.isApprovedStatus(approvalStatus);

  bool get isRejected => RiderLookup.isRejectedStatus(approvalStatus);

  bool get isPendingKyc =>
      phoneVerified &&
      !isApproved &&
      !isRejected &&
      riderId != null &&
      riderId!.isNotEmpty;

  bool get canBook => phoneVerified && isApproved;

  bool get aadhaarFront => aadhaarFrontPath != null;
  bool get aadhaarBack => aadhaarBackPath != null;
  bool get licenseFront => licenseFrontPath != null;
  bool get licenseBack => licenseBackPath != null;
  bool get profilePhoto => profilePhotoPath != null;

  String get phoneDisplay {
    if (phone.length != 10) return phone;
    return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
  }

  void applyLookup(RiderLookup lookup) {
    if (!lookup.found) return;
    if (lookup.riderId != null && lookup.riderId!.isNotEmpty) {
      riderId = lookup.riderId;
    }
    if (lookup.fullName != null && lookup.fullName!.isNotEmpty && fullName.isEmpty) {
      fullName = lookup.fullName!;
    }
    if (lookup.email != null && lookup.email!.isNotEmpty && email.isEmpty) {
      email = lookup.email!;
    }
    approvalStatus = lookup.approvalStatus;
    bookingEnabled = lookup.bookingEnabled || RiderLookup.isApprovedStatus(lookup.approvalStatus);
    persist();
    riderSessionTick.value++;
  }

  void jumpToTab(int i) {
    shellTab = i;
    _tabJump = i;
    riderSessionTick.value++;
  }

  int? takeTabJump() {
    final t = _tabJump;
    _tabJump = null;
    return t;
  }

  Future<String?> freshToken({bool force = false}) async {
    final token = await EvuddyFirebase.freshIdToken(
      storedToken: firebaseIdToken,
      refreshToken: firebaseRefreshToken,
      force: force,
    );
    if (token != null && token.isNotEmpty) {
      firebaseIdToken = token;
      persist();
    }
    return firebaseIdToken;
  }

  Future<RiderLookup?> refreshFromServer({bool forceToken = false}) async {
    if (phone.length != 10) return null;
    final token = await freshToken(force: forceToken);
    if (token == null || token.isEmpty) return null;
    try {
      var lookup = await EvuddyApi.lookupRider(phone: phone, idToken: token);
      if (!lookup.found) {
        final retryToken = await freshToken(force: true);
        if (retryToken != null && retryToken.isNotEmpty && retryToken != token) {
          lookup = await EvuddyApi.lookupRider(phone: phone, idToken: retryToken);
        }
      }
      if (lookup.found) applyLookup(lookup);
      try {
        final mine = await EvuddyApi.myBooking(token);
        if (mine != null) activeBooking = mine;
      } catch (_) {}
      persist();
      return lookup;
    } catch (_) {
      return null;
    }
  }

  void clearSession() {
    phoneVerified = false;
    firebaseIdToken = null;
    firebaseRefreshToken = null;
    firebaseUid = null;
    verificationId = null;
    bookingEnabled = false;
    approvalStatus = '';
    chosenPlan = null;
    chosenDuration = null;
    riderId = null;
    activeBooking = null;
    depositHeld = 0;
    depositStatus = 'none';
    depositBookingId = null;
    persist();
    riderSessionTick.value++;
  }

  Future<void> restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final m = jsonDecode(raw);
      if (m is! Map) return;
      phone = m['phone']?.toString() ?? phone;
      phoneVerified = m['phoneVerified'] == true;
      firebaseUid = m['firebaseUid']?.toString();
      firebaseIdToken = m['firebaseIdToken']?.toString();
      firebaseRefreshToken = m['firebaseRefreshToken']?.toString();
      fullName = m['fullName']?.toString() ?? fullName;
      email = m['email']?.toString() ?? email;
      comingThrough = m['comingThrough']?.toString() ?? comingThrough;
      riderId = m['riderId']?.toString();
      approvalStatus = m['approvalStatus']?.toString() ?? approvalStatus;
      bookingEnabled = m['bookingEnabled'] == true;
      chosenCity = m['chosenCity']?.toString();
      chosenHubId = m['chosenHubId']?.toString();
      chosenPlan = m['chosenPlan']?.toString();
      chosenDuration = m['chosenDuration']?.toString();
      depositHeld = (m['depositHeld'] is num)
          ? (m['depositHeld'] as num).toDouble()
          : depositHeld;
      depositStatus = m['depositStatus']?.toString() ?? depositStatus;
      depositBookingId = m['depositBookingId']?.toString();
    } catch (_) {}
  }

  Future<void> persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _prefsKey,
        jsonEncode({
          'phone': phone,
          'phoneVerified': phoneVerified,
          'firebaseUid': firebaseUid,
          'firebaseIdToken': firebaseIdToken,
          'firebaseRefreshToken': firebaseRefreshToken,
          'fullName': fullName,
          'email': email,
          'comingThrough': comingThrough,
          'riderId': riderId,
          'approvalStatus': approvalStatus,
          'bookingEnabled': bookingEnabled,
          'chosenCity': chosenCity,
          'chosenHubId': chosenHubId,
          'chosenPlan': chosenPlan,
          'chosenDuration': chosenDuration,
          'depositHeld': depositHeld,
          'depositStatus': depositStatus,
          'depositBookingId': depositBookingId,
        }),
      );
    } catch (_) {}
  }
}

const _prefsKey = 'evuddy_rider_session_v1';

final registrationDraft = RegistrationDraft();
final riderSessionTick = ValueNotifier(0);
