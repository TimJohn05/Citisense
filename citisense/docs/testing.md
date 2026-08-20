# Testing Guide

Scope: **Calamba City, Laguna** (Barangay Feedback & Resolution Platform).

## 1. Automated tests

```bash
cd ~/SE2-Project/citisense
flutter analyze   # static checks — must be "No issues found"
flutter test      # runs test/ (currently 13 tests)
```

Current tests:
- `test/widget_test.dart` — app boots to the login screen.
- `test/login_test.dart` — demo citizen login succeeds, logout confirmation dialog works (Cancel + Sign out buttons).
- `test/sentiment_engine_test.dart` — 10 Taglish sentiment tests (street-light, no-water, trash, construction noise, thanks/fixed, negation flip, neutral, etc.)

All tests run on `MockRepository` (no network, no device needed).

Add more: `test/` uses `MockRepository` (no network needed), e.g. test officer resolving
a complaint or admin adding an official. Pattern: `tester.pumpWidget(App(repository: MockRepository()))`.

## 2. On-device (real phone, TECNO LJ6)

```bash
cd ~/SE2-Project/citisense
flutter run -d 14292255AE103649   # live hot-reload during development
flutter build apk --release       # build release APK
~/Android/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
~/Android/platform-tools/adb shell am start -n com.citisense.citisense/.MainActivity
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/CitiSense.apk  # shareable copy
```

## 3. On emulator

```bash
~/Android/emulator/emulator -avd citisense -ports 5554,5555 &
# Wait for boot, then:
~/Android/platform-tools/adb -s emulator-5554 shell am start -n com.citisense.citisense/.MainActivity
```

Requires explicit `-ports` flag — adb bridge does not register without it.

## 4. Manual test matrix

Demo accounts (mock mode): password for all is `password`.

| Role | Email | Key flows to verify |
| --- | --- | --- |
| Citizen | `citizen@citisense.com` | Login → home dashboard → Report Issue (category, description, evidence photo, map pin with crosshair indicator, sentiment result) → My Reports + filters → track status |
| Officer | `officer@citisense.com` | Dashboard stats + bar chart → complaints feed (status/category filters) → Acknowledge → Resolve (REQUIRED proof photo) / Reject (reason) |
| Admin | `admin@citisense.com` | Dashboard charts (status bar, category bars, sentiment pie) → User management (add officer, revoke/restore) → All complaints (delete) → Audit logs |

Cross-cutting checks (do in both **Light** and **Dark** mode):
1. Open Settings (gear icon on every dashboard) → toggle Light / Dark / System.
2. Verify light mode = white surfaces + dark text; dark mode = dark surfaces + light text.
3. Verify high-contrast toggle keeps contrast in both modes.
4. Check filter chips, spinners, cards/borders, charts render with correct colors.
5. Location: center crosshair indicator visible on map picker → tap pin button to place marker → GPS crosshair jumps to current location.
6. Logout: tap logout icon → "Sign out?" dialog appears with equal-sized Cancel / Sign out buttons.
7. Privacy Policy: accessible from login screen and Settings → About → Privacy Policy.
8. Offline behavior: mock mode works with no network (except map tiles).

## 5. Sentiment engine (offline Taglish)

The app uses a built-in Taglish lexicon engine (`lib/services/sentiment_engine.dart`) that works fully offline. No API calls needed.

For the optional real ML model, see `docs/sentiment-service.md` — FastAPI + transformers service
(when the phone is USB-connected: `adb reverse tcp:8000 tcp:8000`).
