# EVUDDY

Rider app for EVUDDY. Frontend only — website APIs are not called yet.

White screens, black type, green for success, pink only inside the EVUDDY mark. Splash uses the real letters lockup at a readable size. Headers use a typeset **EV + bolt + UDDY** so the name never shrinks into mush.

Splash → mobile → OTP → details → verified → KYC → documents → submitted.

OTP: any 6 digits. Documents: tap to mark attached.

```bash
git pull origin main
flutter pub get
flutter run
```

Do a full restart after this pull (not hot reload) so the letters asset loads.
