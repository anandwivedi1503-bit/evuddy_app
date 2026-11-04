# Evuddy rider app — Play publication checklist

## Done in repo (main)

- Launcher icon + label **Evuddy** (v1.0.37+38)
- Play assets under `assets/store/` (512 icon, feature graphic)
- Shared API host: `https://www.evuddy.com`

## You do on your PC

```bash
git checkout main
git pull origin main
flutter pub get
flutter build appbundle --release
```

Upload: `build/app/outputs/flutter-apk/app-release.aab` → wrong path  
Correct: `build/app/outputs/bundle/release/app-release.aab`

Signing: `android/app/key.properties` + upload keystore.

## Firebase

Project **kebuone-otp**, app **com.evuddy.app**: add upload keystore SHA-1 + Play App signing SHA-1.

## Play Console order

1. **Internal testing** — upload AAB, install on phone, smoke test (OTP, Book EV)
2. **Store presence** — name Evuddy, icon/feature graphic from `assets/store/`, ≥2 phone screenshots
3. **App content** — access, ads, content rating, data safety, privacy URL
4. **Production** — submit for review → rollout

## Backend (separate repo)

Apply **`docs/kebuone-launch-alignment.patch`** on **kebuone-website** before or right after first production release. See **`docs/KEBUONE_WEBSITE_APPLY.md`**.
