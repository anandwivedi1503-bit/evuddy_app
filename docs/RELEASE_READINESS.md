# Release readiness (Evuddy rider app)

## Fixed in this release (1.0.39+40)

- **Launcher icon:** new EV + bolt with spacing; more padding on adaptive icon (less “cramped”).
- **Android 12+ splash:** was white + tiny icon (`drawable-v21`); now **yellow + wordmark** like older Android.
- **Flutter splash:** fades to **cream** (not harsh white) with larger wordmark.
- **Home:** **Ride plans** (Hourly, Daily, Weekly, Monthly, Rent to Own) visible for **all** riders (not only after admin approve).
- **Fleet partner screen:** removed overlapping yellow scooter; clean yellow card + plan chips.

## Security & booking logic (app + evuddy.com)

| Risk | Where enforced |
|------|----------------|
| Two riders same scooter | **Server** marks vehicle `Available` / booked; app only lists **Available** scooters (`EvuddyVehicle.isBookable`). |
| Double Razorpay order | App **single POST** to `create-order` (`attempts: 1`); remaining pay uses **new** `order_` after ₹1 (website rule). |
| New booking while trip open | App **`hasLiveBooking`** blocks home/book flow; server **`/api/bookings/mine`**. |
| Pickup / ride-end OTP | **Server** generates; yard enters OTP (same as website). |
| Vehicle unlock | **Yard/admin** on CRM after pickup OTP — not client-side auto-unlock in app. |
| Payment verify | **`/api/razorpay/verify-payment`** with Firebase token — server authoritative. |

The app does **not** bypass website payment or OTP rules; keys stay on **evuddy.com**.

## Before Production AAB

1. `git pull origin main` (after this PR merges).
2. `flutter build appbundle --release`.
3. Install → check icon, splash, **Ride plans** on home, fleet screen layout.
4. One OTP login + open Book EV (smoke test).

## Play Console

Upload **1.0.39 (40)** only. Do not promote old **35 (36)** internal build to Production.
