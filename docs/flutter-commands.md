# CitiSense — Flutter Commands Cheat Sheet

## Development

```bash
# Static analysis — must pass before finishing any session
flutter analyze

# Unit + widget tests
flutter test

# Run locally on Linux desktop
flutter run -d linux
```

## Build & Install (Android)

```bash
# Build release APK
flutter build apk --release

# Install to connected device ($ANDROID_HOME or $PATH should have adb)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Launch the app
adb shell am start -n com.citisense.citisense/.MainActivity
```

## Integration Test (on-device)

```bash
# IMPORTANT: run adb uninstall first to avoid the adb race condition
adb uninstall com.citisense.citisense

# Run the e2e suite (installs, runs, uninstalls automatically)
flutter test integration_test/e2e_test.dart

# Reinstall the app after e2e (the test uninstalls it on completion)
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** `flutter test integration_test/...` manages the full app lifecycle — install → run → uninstall. The app will not remain on the device after the test completes.

## Utilities

```bash
# Check connected devices
adb devices

# Force-stop the app
adb shell am force-stop com.citisense.citisense

# List installed packages
adb shell pm list packages | grep citisense
```
