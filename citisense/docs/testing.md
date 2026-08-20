# Testing Guide

Scope: **Calamba City, Laguna** (Barangay Feedback & Resolution Platform).

## 1. Automated tests

```bash
cd ~/SE2-Project/citisense
flutter analyze   # static checks — must be "No issues found"
flutter test      # runs test/ (currently 2 widget tests)
```

Current tests:
- `test/widget_test.dart` — app boots to the login screen.
- `test/login_test.dart` — demo citizen login succeeds and reaches the dashboard.

Add more: `test/` uses `MockRepository` (no network needed), e.g. test officer resolving
a complaint or admin adding an official. Pattern: `tester.pumpWidget(App(repository: MockRepository()))`.

## 2. On-device (real phone, TECNO LJ6)

```bash
flutter run -d 14292255AE103649   # live hot-reload during development
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.citisense.citisense/.MainActivity
```

## 3. Manual test matrix

Demo accounts (mock mode): password for all is `password`.

| Role | Email | Key flows to verify |
| --- | --- | --- |
| Citizen | `citizen@citisense.com` | Login → home dashboard → Report Issue (category, description, evidence photo, map pin near Calamba, sentiment result) → My Reports + filters → track status |
| Officer | `officer@citisense.com` | Dashboard stats → complaints feed (status/category filters) → Acknowledge → Resolve (REQUIRED proof photo) / Reject (reason) |
| Admin | `admin@citisense.com` | Dashboard charts → User management (add officer, revoke/restore) → All complaints (delete) → Audit logs |

Cross-cutting checks (do in both **Light** and **Dark** mode):
1. Open Settings (gear icon on every dashboard) → toggle Light / Dark / System.
2. Verify light mode = white surfaces + dark text; dark mode = dark surfaces + light text.
3. Verify high-contrast toggle keeps contrast in both modes.
4. Check filter chips, spinners, cards/borders, charts render with correct colors.
5. Location: "use my location" should place the marker near the device's real position in Calamba.
6. Offline behavior: mock mode works with no network (except map tiles).

## 4. Sentiment (optional, real model)

See `docs/sentiment-service.md` for running the FastAPI + transformers service,
then on a device connected over adb: `adb reverse tcp:8000 tcp:8000`.
