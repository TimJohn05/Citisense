# CitiSense — Flutter Commands Cheat Sheet

## Development

```bash
# Static analysis — must pass before finishing any session
flutter analyze

# Unit + widget tests (29 tests)
flutter test

# Run locally on Linux desktop
flutter run -d linux
```

## Build & Install (Android)

```bash
# Build release APK
flutter build apk --release

# Install to connected device
~/Android/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk

# Launch the app
~/Android/platform-tools/adb shell am start -n com.citisense.citisense/.MainActivity

# Copy APK to desktop for quick sharing
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/CitiSense.apk
```

## One-liner (phone connected, USB debugging on)

```bash
cd ~/SE2-Project/citisense && flutter build apk --release && \
~/Android/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk && \
~/Android/platform-tools/adb shell am start -n com.citisense.citisense/.MainActivity && \
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/CitiSense.apk
```

## Integration Test (on-device, TECNO phone)

```bash
# IMPORTANT: run adb uninstall first to avoid the adb race condition
~/Android/platform-tools/adb uninstall com.citisense.citisense

# Run the e2e suite (installs, runs, uninstalls automatically)
cd ~/SE2-Project/citisense
flutter test integration_test/e2e_test.dart

# Reinstall the app after e2e (the test uninstalls it on completion)
~/Android/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** `flutter test integration_test/...` manages the full app lifecycle — install → run → uninstall. The app will not remain on the device after the test completes.

## Emulator

```bash
~/Android/emulator/emulator -avd citisense -ports 5554,5555 &
```

Requires explicit `-ports` for `adb` to register the device.

## Utilities

```bash
# Check connected devices
~/Android/platform-tools/adb devices

# Force-stop the app
~/Android/platform-tools/adb shell am force-stop com.citisense.citisense

# List installed packages
~/Android/platform-tools/adb shell pm list packages | grep citisense

# Full session bootstrap (reads handoff + project context)
bash ~/SE2-Project/session-start.sh
```
