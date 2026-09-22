# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## Look

Cream canvas, official lockup, yellow scooter + riding-person photos.

Home now has **Rapido-style partner ads** (investment / dealer / distributor from the live partners page), **fare cards** with GST and a Popular daily rate, and a one-tap Book EV overlay.

## What you get

- **Home** — ride photo, investment carousel, fare cards, live hubs, 24×7 call
- **Invest** — ₹1L / ₹5L / ₹10L poster math, apply on evuddy.com (no payment in the app)
- **Book EV** — confirm mobile → OTP → rental vs Rent to Own
- **OTP** — Firebase Recaptcha + **SMS autofill** (`oneTimeCode`). We do not read the full inbox.
- **Register / KYC / documents** — `POST /api/upload` + `POST /api/riders`
- **Account** — status, investment, helpdesk, logout

```bash
git pull origin main
flutter pub get
flutter run
```

Full restart after pull. For a CEO APK: `flutter build apk --release` then send `build/app/outputs/flutter-apk/app-release.apk`.
