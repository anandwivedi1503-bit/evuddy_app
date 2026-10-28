# Deploy EVUDDY CRM + GPS + receipts (kebuone-website)

Use this on a PC where you can push to GitHub (not the cloud bot).

## 1. Clone or open the website repo

```powershell
cd C:\Users\andff
git clone https://github.com/anandwivedi1503-bit/kebuone-website.git
cd kebuone-website
```

If you already have the folder, just `cd` into it and `git fetch origin`.

## 2. Create / use the CRM branch

```powershell
git fetch origin
git checkout main
git pull origin main
git checkout -b cursor/crm-rider-safety-a534
```

Copy in any missing files from the cloud agent if needed, then:

```powershell
git add src/app/api/rider/location/
git add src/app/api/admin/rider-safety/
git add src/app/api/riders/me/
git add src/app/api/receipts/deliver/
git add src/app/api/notify/rental-end-reminder/
git add src/app/api/notify/payment-receipt/
git add src/lib/riderSafetyOps.ts
git add src/lib/adminCommandCenter.ts
git add src/lib/notify/paymentReceiptDeliver.ts
git add src/lib/notify/rentalEndReminder.ts
git add src/models/Booking.ts
git add src/app/components/AdminDashboard/RiderSafetyBoard.tsx
git add src/app/components/AdminDashboard/AdminDashboard.tsx
git add src/app/components/IoTDashboard/IoTDashboard.tsx
git add src/app/api/riders/route.ts
git status
git commit -m "CRM: rider phone GPS, safety board, receipts, profile API"
git push -u origin cursor/crm-rider-safety-a534
```

## 3. Open PR and merge to main

On GitHub: **kebuone-website** → Pull requests → **New PR**  
Base: `main` ← Compare: `cursor/crm-rider-safety-a534` → Merge.

## 4. Deploy production (Vercel)

1. Open [Vercel](https://vercel.com) → project **kebuone-website** (evuddy.com).
2. After merge, wait for **Production** deploy **Ready**.
3. Or: Deployments → Redeploy latest **main**.

## 5. Environment variables (Vercel → Settings → Environment Variables)

Required for CRM + GPS + SMS + email:

| Variable | Purpose |
|----------|---------|
| `MONGODB_URI` | Bookings, GPS fields, riders |
| Firebase admin vars (same as today) | `POST /api/rider/location` auth |
| `RESEND_API_KEY` | Receipt + payment emails |
| `NOTIFY_FROM_EMAIL` | From address |
| `MSG91_AUTH_KEY` or `FAST2SMS_API_KEY` | SMS to registered mobile |
| `MSG91_SENDER_ID` / template if you use MSG91 flow | DLT SMS |

## 6. Verify CRM after deploy

1. Admin: https://www.evuddy.com/dashboard  
2. **Rider Safety** section on home — active trips + countdown level  
3. **IoT / map** — pins from `riderPhoneLat` / `riderPhoneLng` when rider is **In Ride** and app sends GPS  
4. Rider pays → email + SMS (if SMS env set)  
5. App **Account → Edit profile** → saves via `POST /api/riders/me`

## 7. Live GPS path (Rapido-style ops view)

```text
Rider app (In Ride, location ON)
  → POST /api/rider/location (Firebase token)
  → MongoDB booking.riderPhoneLat/Lng
  → GET /api/admin/rider-safety + IoT map (admin session)
```

Rider **logout** does **not** delete the server booking; it only clears timer/alerts on the phone until OTP login again.
