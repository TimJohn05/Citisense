# CitiSense

**Urban feedback & resolution platform for Barangays of Calamba City, Laguna.**

Report community issues with photos/videos & map location. Barangay officials receive
notifications and resolve complaints with proof. Admin gets full oversight with dashboards.

## Tech Stack

- **Language:** Dart
- **Framework:** Flutter (Material 3)
- **Maps:** flutter_map + OpenStreetMap
- **Location:** geolocator
- **Camera:** image_picker + permission_handler
- **State:** provider (ChangeNotifier)
- **Charts:** fl_chart
- **Backend:** Firebase (Auth + Firestore + Storage)
- **Video:** Cloudinary (unsigned upload + signed delivery URLs)
- **Font:** Public Sans

**Architecture:** Repository pattern — offline with `MockRepository` by default,
switchable to `FirebaseRepository` via `--dart-define=USE_FIREBASE=true`.

## Quick Start

```bash
cd citisense
flutter pub get
flutter run        # mock mode, no backend needed
```

**Demo accounts (mock mode):**

| Role | Email | Password |
|------|-------|----------|
| Citizen | `citizen@citisense.com` | `password` |
| Officer | `officer@citisense.com` | `password` |
| Admin | `admin@citisense.com` | `password` |

## Download

Download the latest APK from [GitHub Releases](https://github.com/TimJohn05/Citisense/releases/latest).

## Documentation

- [Flutter Commands](docs/flutter-commands.md) — build, install, and test cheat sheet
- `citisense/README.md` — full project guide (Firebase setup, Firestore schema, testing)

## License

Built as the **Software Engineering 2** university project.