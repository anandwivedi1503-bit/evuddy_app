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
  bool dismissedCompleted = false;
  double depositHeld = 0;
  String depositStatus = 'none'; // none | held | refund_pending | released
  String? depositBookingId;
  double walletAvailable = 0;
  String walletStatus = '';

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

  String rtoNomineeName = '';
  String rtoNomineeRelation = 'Father';
  String rtoGuardianName = '';
  String rtoEmergencyPhone = '';
  String rtoAddress = '';
  String rtoOccupation = '';
  bool rtoAgreed = false;

  RtoAgreement get rtoAgreement => RtoAgreement(
        nomineeName: rtoNomineeName,
        nomineeRelation: rtoNomineeRelation,
        guardianName: rtoGuardianName,
        emergencyPhone: rtoEmergencyPhone,
        email: email,
        address: rtoAddress,
        occupation: rtoOccupation,
        agreed: rtoAgreed,
      );

  bool get hasPersonalProfile {
    final n = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final e = email.trim().toLowerCase();
    return RtoAgreement.namePattern.hasMatch(n) &&
        RtoAgreement.emailPattern.hasMatch(e);
  }

  /// Phone-first Book EV always collects name + email after OTP.
  /// Home Register already collected them, so OTP continues to KYC.
  bool get shouldCollectPersonalAfterOtp =>
      otpGate != 'register' || !hasPersonalProfile;

  void resetProfileForNewPhone() {
    fullName = '';
    email = '';
    comingThrough = 'Direct / EVUDDY';
    aadhaar = '';
    drivingLicense = '';
    instagramId = '';
    facebookId = '';
    reference1Name = '';
    reference1Phone = '';
    reference2Name = '';
    reference2Phone = '';
    aadhaarFrontPath = null;
    aadhaarBackPath = null;
    licenseFrontPath = null;
    licenseBackPath = null;
    profilePhotoPath = null;
    riderId = null;
    approvalStatus = '';
    bookingEnabled = false;
    activeBooking = null;
  }

  /// Website `/api/bookings/mine` — skip plan pick while this booking is live.
  bool get hasLiveBooking {
    final b = activeBooking;
    if (b == null || b.bookingId.isEmpty) return false;
    if (b.completed || b.cancelled) return false;
    if (b.inRide || b.readyForPickup || b.hasPickupOtp || b.pickupOtpVerified) {
      return true;
    }
    final pay = b.paymentStatus.toLowerCase();
    if (pay == 'pending' || pay == 'partial' || pay.contains('pending')) {
      return true;
    }
    final status = b.rideStatus.toLowerCase();
    if (status.isEmpty && b.mongoId.isEmpty) return false;
    return status.isNotEmpty;
  }

  /// Keep the thank-you workspace until the rider starts a new Normal / RTO booking.
  bool get showRideWorkspace {
    if (hasLiveBooking) return true;
    final b = activeBooking;
    return b != null && b.completed && !dismissedCompleted;
  }

  /// After a closed ride, return to Normal / Rent to Own instead of the last page.
  Future<void> startFreshBooking() async {
    dismissedCompleted = true;
    activeBooking = null;
    chosenPlan = null;
    chosenDuration = null;
    await persist();
    riderSessionTick.value++;
  }

  void applyActiveBooking(RiderBooking? mine) {
    if (mine != null && (mine.completed || mine.cancelled) && dismissedCompleted) {
      activeBooking = null;
      persist();
      riderSessionTick.value++;
      return;
    }
    activeBooking = mine;
    if (mine == null || mine.bookingId.isEmpty) {
      persist();
      riderSessionTick.value++;
      return;
    }
    if (!mine.completed && !mine.cancelled) {
      dismissedCompleted = false;
    }
    if (mine.isRentToOwn) {
      chosenPlan = 'rto';
      chosenDuration = 'Rent To Own';
    } else {
      chosenPlan = 'rental';
      const modes = ['Hourly', 'Daily', 'Weekly', 'Monthly'];
      if (modes.contains(mine.rentalMode)) {
        chosenDuration = mine.rentalMode;
      } else {
        chosenDuration ??= 'Daily';
      }
    }
    if (mine.city.isNotEmpty) chosenCity = mine.city;
    persist();
    riderSessionTick.value++;
  }

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
    if (lookup.fullName != null && lookup.fullName!.isNotEmpty) {
      fullName = lookup.fullName!;
    }
    if (lookup.email != null && lookup.email!.isNotEmpty) {
      email = lookup.email!;
    }
    approvalStatus = lookup.approvalStatus;
    bookingEnabled = lookup.bookingEnabled || RiderLookup.isApprovedStatus(lookup.approvalStatus);
    walletAvailable = lookup.walletAvailable;
    walletStatus = lookup.walletStatus;
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
      expectedUid: firebaseUid,
      force: force,
    );
    if (token != null && token.isNotEmpty && !EvuddyFirebase.jwtExpired(token)) {
      firebaseIdToken = token;
      final nextRefresh = EvuddyFirebase.lastRefreshToken;
      if (nextRefresh != null && nextRefresh.isNotEmpty) {
        firebaseRefreshToken = nextRefresh;
      }
      persist();
      return token;
    }
    return null;
  }

  bool isAuthError(Object e) {
    final m = e.toString().toLowerCase();
    return m.contains('sign in again') ||
        m.contains('sign in required') ||
        m.contains('registered mobile') ||
        m.contains('unauthorized') ||
        m.contains('id token verification');
  }

  Future<void> logout() async {
    try {
      await EvuddyFirebase.ensure();
      await EvuddyFirebase.signOut();
    } catch (_) {}
    await clearSession();
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
        applyActiveBooking(await EvuddyApi.myBooking(token));
      } catch (_) {}
      persist();
      return lookup;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    phone = '';
    phoneVerified = false;
    firebaseIdToken = null;
    firebaseRefreshToken = null;
    firebaseUid = null;
    verificationId = null;
    resetProfileForNewPhone();
    chosenPlan = null;
    chosenDuration = null;
    chosenCity = null;
    chosenHubId = null;
    otpGate = 'register';
    depositHeld = 0;
    depositStatus = 'none';
    depositBookingId = null;
    walletAvailable = 0;
    walletStatus = '';
    rtoNomineeName = '';
    rtoNomineeRelation = 'Father';
    rtoGuardianName = '';
    rtoEmergencyPhone = '';
    rtoAddress = '';
    rtoOccupation = '';
    rtoAgreed = false;
    dismissedCompleted = false;
    await persist();
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
      rtoNomineeName = m['rtoNomineeName']?.toString() ?? rtoNomineeName;
      rtoNomineeRelation = m['rtoNomineeRelation']?.toString() ?? rtoNomineeRelation;
      rtoGuardianName = m['rtoGuardianName']?.toString() ?? rtoGuardianName;
      rtoEmergencyPhone = m['rtoEmergencyPhone']?.toString() ?? rtoEmergencyPhone;
      rtoAddress = m['rtoAddress']?.toString() ?? rtoAddress;
      rtoOccupation = m['rtoOccupation']?.toString() ?? rtoOccupation;
      rtoAgreed = m['rtoAgreed'] == true;
      dismissedCompleted = m['dismissedCompleted'] == true;
      depositHeld = (m['depositHeld'] is num)
          ? (m['depositHeld'] as num).toDouble()
          : depositHeld;
      depositStatus = m['depositStatus']?.toString() ?? depositStatus;
      depositBookingId = m['depositBookingId']?.toString();
      walletAvailable = (m['walletAvailable'] is num)
          ? (m['walletAvailable'] as num).toDouble()
          : walletAvailable;
      walletStatus = m['walletStatus']?.toString() ?? walletStatus;
      final rawBooking = m['activeBooking'];
      if (rawBooking is Map) {
        activeBooking = RiderBooking.fromJson(rawBooking);
        if (activeBooking!.isRentToOwn) {
          chosenPlan = 'rto';
          chosenDuration = 'Rent To Own';
        } else if (activeBooking!.rentalMode.isNotEmpty) {
          chosenPlan = 'rental';
        }
      }
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
          'rtoNomineeName': rtoNomineeName,
          'rtoNomineeRelation': rtoNomineeRelation,
          'rtoGuardianName': rtoGuardianName,
          'rtoEmergencyPhone': rtoEmergencyPhone,
          'rtoAddress': rtoAddress,
          'rtoOccupation': rtoOccupation,
          'rtoAgreed': rtoAgreed,
          'dismissedCompleted': dismissedCompleted,
          'depositHeld': depositHeld,
          'depositStatus': depositStatus,
          'depositBookingId': depositBookingId,
          'walletAvailable': walletAvailable,
          'walletStatus': walletStatus,
          if (activeBooking != null) 'activeBooking': activeBooking!.toJson(),
        }),
      );
    } catch (_) {}
  }
}

const _prefsKey = 'evuddy_rider_session_v1';

final registrationDraft = RegistrationDraft();
final riderSessionTick = ValueNotifier(0);
