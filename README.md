# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## Look

Premium cream canvas, official lockup, **peeking photo carousel** with **Book EV on the picture**, advertisement-style partner banners, and fare cards with live scene photos.

## What you get

- **Home** — “Where are you riding today?”, rider photo with Book EV on the picture, dealer ads, white fare cards
- **Invest** — official poster + ₹1L / ₹5L / ₹10L math, apply on evuddy.com
- **Book EV** — confirm mobile → OTP autofill → rental vs Rent to Own → reserve live scooter → Razorpay → yard pickup OTP
- **OTP** — Firebase Recaptcha + Web OTP / SMS autofill after the code is sent
- **Voice** — microphone on register / KYC fields (and “speak the whole form”)
- **Account** — status, open booking OTP, helpdesk

```bash
git pull origin main
flutter pub get
flutter run
```

Full restart after pull. CEO APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
