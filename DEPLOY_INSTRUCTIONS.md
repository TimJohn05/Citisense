# CitiSense — Manual Deploy Instructions

## Prerequisites
- Connected Android device (TECNO LJ6, `14292255AE103649`) with USB debugging enabled
- `adb` in PATH (`~/Android/platform-tools/adb`)
- Flutter SDK installed and in PATH
- Cloudinary API secret (rotated, not the exposed one)

## One-Command Deploy

```bash
cd ~/SE2-Project
CLOUDINARY_API_SECRET=YOUR_ROTATED_SECRET ./deploy.sh
```

**Tip:** Prefix with space to keep secret out of shell history:
```bash
 CLOUDINARY_API_SECRET=YOUR_ROTATED_SECRET ./deploy.sh
```

## What deploy.sh Does
1. Builds release APK with:
   - `--dart-define=USE_FIREBASE=true` (Firebase mode)
   - Cloudinary credentials (API key + secret)
2. Installs APK on connected device via `adb install -r`
3. Copies installed APK to device at `/sdcard/Citisense/CitiSense_latest.apk`
4. Also outputs APK at `citisense/build/app/outputs/flutter-apk/app-release.apk`

## Manual Step-by-Step (if script fails)

```bash
# 1. Navigate to project
cd ~/SE2-Project/citisense

# 2. Build with Firebase + Cloudinary
flutter build apk --release \
  --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=epbrrian \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=citisense_videos \
  --dart-define=CLOUDINARY_API_KEY=975724951211727 \
  --dart-define=CLOUDINARY_API_SECRET=YOUR_ROTATED_SECRET

# 3. Install on device
~/Android/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk

# 4. Copy to /sdcard/Citisense
~/Android/platform-tools/adb shell "mkdir -p /sdcard/Citisense && cp \$(pm path com.citisense.citisense | cut -d: -f2) /sdcard/Citisense/CitiSense_latest.apk"
```

## Verify on Device
1. Open CitiSense app
2. Sign up with new email (demo accounts only work in mock mode)
3. File a report with video → check Cloudinary Console → Media Library
3. Check Remote Config in Firebase Console for version updates

## Files
- `deploy.sh` — main deploy script (in `.gitignore`)
- `build-release.sh` — build only (in `.gitignore`)
- `CLOUDINARY_API_SECRET` — never commit, pass via env var only