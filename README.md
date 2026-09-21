# EVUDDY

Flutter rider app. It talks to **https://www.evuddy.com** the same way the website register page does. **The website repo and server code were not changed.**

## Screens (match `/register`)

1. Personal information — name, mobile, email, coming through  
2. Firebase phone OTP (`kebuone-otp`)  
3. KYC — Aadhaar, optional licence / social / references  
4. Documents — upload via `POST /api/upload`, then `POST /api/riders`

Existing numbers: after OTP, `GET /api/riders?phone=` with the Firebase token. Approved riders skip KYC.

## Run

```bash
git pull origin main
flutter pub get
flutter run
```

Full restart after this pull.

Phone OTP needs a real Android/iPhone and the `kebuone-otp` Firebase app. If SMS fails with app-not-authorized, add this app’s SHA-1 in Firebase (console only — still no website code change).

## Not in this slice

Book EV, wallet, map, Razorpay — next pages after this register path is confirmed live.
