class RegistrationDraft {
  String phone = '';
  bool phoneVerified = false;

  String fullName = '';
  String email = '';
  String dateOfBirth = '';
  String comingThrough = 'Direct / EVUDDY';

  String aadhaar = '';
  String pan = '';
  String drivingLicense = '';
  String address = '';
  String pinCode = '';
  String reference1Name = '';
  String reference1Phone = '';
  String reference2Name = '';
  String reference2Phone = '';

  bool aadhaarFront = false;
  bool aadhaarBack = false;
  bool licenseFront = false;
  bool licenseBack = false;
  bool profilePhoto = false;

  String get phoneDisplay {
    if (phone.length != 10) return phone;
    return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
  }
}

final registrationDraft = RegistrationDraft();
