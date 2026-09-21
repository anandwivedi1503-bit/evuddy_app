# EVUDDY Flutter app

Frontend-only rider app from VS Code. **Backend is not connected.** Website APIs are unchanged.

## Figma vs website (register / KYC)

Kept the Figma page order:

Splash → mobile → OTP → personal info → verification confirm → KYC → documents → received.

| On Figma (your screens) | On website (`/register`) | What we did |
| --- | --- | --- |
| Mobile + 6-digit OTP | Firebase phone OTP (one SMS) | Same pages; OTP is UI-only |
| Name, email, DOB | Name, email, **coming through** — no DOB | Kept DOB; added coming through |
| Second OTP page | No second SMS | Confirmation that the number is verified |
| Aadhaar, PAN, address, PIN | Aadhaar, optional **licence number**, **two references** | Kept Figma fields; added licence + references |
| One “Driving licence” upload | Aadhaar front/back, **profile photo**, licence front/back optional | Five document tiles |

## Run

```bash
flutter pub get
flutter run
```

OTP: enter any 6 digits to move forward. Documents: tap to mark attached. Nothing is uploaded.
