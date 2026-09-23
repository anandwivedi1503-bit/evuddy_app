# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## Look

Premium cream canvas, official lockup, **peeking photo carousel** with **Book EV on the picture**, advertisement-style partner banners, and fare cards with live scene photos.

## What you get

- **Home** — “Where are you riding today?”, rider photo with Book EV on the picture, dealer ads, white fare cards
- **Invest** — official poster + ₹1L / ₹5L / ₹10L math, apply on evuddy.com
- **Book EV** — confirm mobile → OTP autofill → rental vs Rent to Own → reserve live scooter → Razorpay → yard pickup OTP
- **OTP** — Recaptcha (“I’m not a robot” / picture challenge) first, then Firebase SMS and autofill
- **Voice** — microphone on register / KYC fields (and “speak the whole form”)
- **Account** — status, open booking OTP, helpdesk

## Why the emulator does not update after a merge

GitHub merge only updates the remote. **sdk gphone16k still runs the last APK** from `flutter run`. Hot reload does not load another machine’s merge. The Cursor Agents phone on the right is a website-style preview, not your emulator.

**Fix (Windows):** press `q` in the old Flutter terminal, then double-click `tool/update_emulator.bat`  
(or VS Code → Terminal → Run Task → **EVUDDY: pull main and run emulator**).

That pulls `main`, **uninstalls the old app**, and installs this build. Splash is forest green with the EVUDDY wordmark on white.

```bash
# press q in the running flutter terminal first
git checkout main
git pull origin main
flutter pub get
flutter run --uninstall-first
```

Full restart after pull. CEO APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
