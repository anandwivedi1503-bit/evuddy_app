class RegistrationDraft {
  String phone = '';
  bool phoneVerified = false;
  String? firebaseUid;
  String? firebaseIdToken;
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

  bool get aadhaarFront => aadhaarFrontPath != null;
  bool get aadhaarBack => aadhaarBackPath != null;
  bool get licenseFront => licenseFrontPath != null;
  bool get licenseBack => licenseBackPath != null;
  bool get profilePhoto => profilePhotoPath != null;

  String get phoneDisplay {
    if (phone.length != 10) return phone;
    return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
  }
}

final registrationDraft = RegistrationDraft();
