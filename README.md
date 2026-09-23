# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## Look

Premium cream canvas, official lockup, **full yellow scooter** (never cropped), scenes that rotate one-by-one, and the **official fleet-partner poster** as in-app ads.

## What you get

- **Home** — scene carousel, one-tap Book EV, 3-step ride, partner posters, fare cards, live hubs
- **Invest** — official poster + ₹1L / ₹5L / ₹10L math, apply on evuddy.com
- **Book EV** — confirm mobile → OTP autofill → rental vs Rent to Own → reserve live scooter → Razorpay → yard pickup OTP
- **OTP** — Firebase Recaptcha + SMS `oneTimeCode` autofill
- **Account** — status, poster, helpdesk

```bash
git pull origin main
flutter pub get
flutter run
```

Full restart after pull. CEO APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
