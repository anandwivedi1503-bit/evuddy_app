# EVUDDY Flutter app

Frontend-only rider app. **Backend is not connected.** Website APIs are unchanged.

## Look

Splash uses the real green / pink EVUDDY wordmark on a night canvas with moving light orbs. Forms are light: floating cards, green focus rings, pill choices, and a sticky action bar.

## Figma vs website (register / KYC)

Splash → mobile → OTP → personal info → verification confirm → KYC → documents → received.

OTP: any 6 digits. Documents: tap to mark attached. Nothing is uploaded.

## Run

```bash
git pull origin main
flutter pub get
flutter run
```

Do a full restart (not hot reload) after this pull so splash assets load.
