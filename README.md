# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified.

## Look

Premium cream canvas, official lockup, Rapido-style yellow splash, a **Book an EV** search bar (not overlapping the photo), bright partner ads, and fare cards.

## What you get

- **Home** — “Where are you riding today?”, Book an EV bar, photo carousel, dealer ads, live trip banner after payment
- **Book EV** — OTP → admin approval unlocks Normal booking and Rent to Own automatically → reserve → Razorpay → pickup OTP
- **OTP** — Recaptcha first, then Firebase SMS and autofill
- **Voice** — microphone on register / KYC fields
- **Account** — live approval status, open booking OTP, helpdesk

## Why the emulator does not update after a merge

GitHub merge only updates the remote. **sdk gphone16k still runs the last APK** from `flutter run`. Hot reload does not load another machine’s merge. The Cursor Agents phone on the right is a website-style preview, not your emulator.

**Fix (Windows):** press `q` in the old Flutter terminal, then double-click `tool/update_emulator.bat`  
(or VS Code → Terminal → Run Task → **EVUDDY: pull main and run emulator**).

That pulls `main`, **uninstalls the old app**, and installs this build. Splash is Rapido-style yellow with the EVUDDY wordmark.

```bash
# press q in the running flutter terminal first
git checkout main
git pull origin main
flutter pub get
flutter run --uninstall-first
```

Full restart after pull. CEO APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
