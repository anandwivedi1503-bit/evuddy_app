# EVUDDY rider app

Same APIs as [evuddy.com](https://www.evuddy.com). Website source is not modified. Booking, Razorpay, pickup OTP and ride-end OTP follow `kebuone-website`.

## Look

Premium cream canvas, official lockup, Rapido-style yellow splash, a **Book an EV** search bar, fleet-partner ads with a calculator, and fare cards.

## What you get

- **Home** — Book an EV bar, photo carousel, fleet ads (calculator), live trip banner after payment
- **Book EV** — confirm mobile → admin Approve unlocks booking → city/hub → scooter → reserve → Razorpay (from ₹1) → **pickup OTP** → yard confirms → Mark ride started → pay remaining → **Generate ride-end OTP** (not for Rent to Own)
- **OTP** — Firebase SMS for login; booking OTPs come from evuddy.com (`/api/notify/booking-otp`, `/api/rides/rider-start`, `/api/rides/rider-end`)
- **Fleet calculator** — investors enter scooters or rupees and see fleet size + monthly return; business planner sees annual, 48-month and FOCO ops. Numbers match the Fleet Partner PDF (₹60,000 / ₹90,000 per scooter)
- **Account** — approval, copyable pickup / ride-end OTP, deposit hold, calculator

## CEO handover (merge + deploy)

This agent cannot merge GitHub PRs or publish Play Store builds. A repo admin (you or CEO with GitHub write) should:

1. **Merge this PR into `main`** on GitHub (Merge pull request).
2. Pull and build the Android APK:

```bash
git checkout main
git pull origin main
flutter pub get
flutter build apk --release
```

APK path: `build/app/outputs/flutter-apk/app-release.apk`

3. **Play Store / sideload:** install that APK. Live payments use evuddy.com Razorpay (`Shubhrax Mobility Limited`). Firebase OTP uses the app’s Google services files already in this repo.
4. **Website:** keep evuddy.com deployed (bookings, OTP, Razorpay keys live there). The app does not host payment keys.
5. **Emulator after merge:** press `q` in the old Flutter terminal, then `tool/update_emulator.bat` (or `flutter run --uninstall-first`).

No invest money is taken in-app. Partners apply on evuddy.com/partners.

## Why the emulator does not update after a merge

GitHub merge only updates the remote. **sdk gphone16k still runs the last APK** from `flutter run`.

```bash
git checkout main
git pull origin main
flutter pub get
flutter run --uninstall-first
```
