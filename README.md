# EVUDDY app vs website

The **website is one product with two kinds of pages**. The **app is the rider product**, not a copy of every marketing block.

## What the website landing page is for

`https://www.evuddy.com` is the shop window: slogan, partner logos, fare cards, city map story, dealer/distributor pitch, reviews, Book EV / Register buttons.

Those buttons are **doors**, not extra backends:

| On the website | Goes to | In the app |
| --- | --- | --- |
| **Register** | `/register` | Register / KYC flow we already wired |
| **Book EV** | `/ride-options` | **Book EV** screen (this slice) |
| Fares ₹60 / ₹230 / … | Same catalog Book EV uses | Shown on Home |
| Lucknow / Kanpur hubs | `/api/cities`, `/api/hubs` | Live list on Home and Book EV |
| Partners, careers, about | `/partners`, `/about`… | **Not in the rider app** (B2B / brochure) |
| Pay / Razorpay | `/book-bike` after KYC | **Next slice** — not charged yet |

Nothing from the landing page is “wasted.” Marketing stays on the website. The app reuses the **same APIs and the same rider steps**.

## Rider path (both clients)

1. Splash  
2. **Home** — Book EV + Register, live hubs, fares  
3. Register → OTP → KYC → documents (same `POST /api/riders`)  
4. Book EV → pick **Normal booking** or **Rent to Own** → city + hub  
5. Later: scooter + Razorpay (website `/book-bike`) — we have not enabled pay yet  

Ops still approve KYC. Book EV checkout only unlocks when `bookingEnabled` is true, same as the site.

## Run

```bash
git pull origin main
flutter pub get
flutter run
```

Website source is not modified.
