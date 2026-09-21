# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## What you get

- **Home** — real EVUDDY scooter, live hubs, fares, Book EV
- **Book EV** — confirm mobile → OTP → if **already approved**, rental vs Rent to Own (website `/ride-options`). New numbers continue KYC.
- **OTP** — Firebase Recaptcha **inside the app** (same project as the site). This avoids the Android SHA-1 / Play Integrity error.
- **Register / KYC / documents** — `POST /api/upload` + `POST /api/riders`
- **Account** — status + logout

Razorpay pay-at-hub is the next connect, not this slice.

```bash
git pull origin main
flutter pub get
flutter run
```

Full restart. On OTP, complete the checkbox if it appears, then enter the SMS code.
