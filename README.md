# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## Look

Cream canvas, official lockup, and the **yellow scooter + riding person** photos from the live site — not the pink cutout.

## What you get

- **Home** — rider in the city, yellow fleet, live hubs, fares, Book EV
- **Book EV** — confirm mobile → OTP → if **already approved**, rental vs Rent to Own. New numbers continue KYC.
- **OTP** — Firebase Recaptcha **inside a full-height WebView** so image challenges (select cars, buses) can actually appear. Same Firebase project as the site.
- **Register / KYC / documents** — `POST /api/upload` + `POST /api/riders`
- **Account** — status + logout

Razorpay pay-at-hub is the next connect, not this slice.

```bash
git pull origin main
flutter pub get
flutter run
```

Do a **full restart** (not hot reload) so images and the OTP HTML load. On OTP, complete the checkbox or the photo grid if Google shows it, then enter the SMS code.
