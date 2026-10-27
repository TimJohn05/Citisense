# CitiSense

**Urban feedback & resolution platform for Barangays of Calamba City, Laguna** — built with Flutter + Dart.

CitiSense lets citizens report community issues (waste, roads, water, lighting) with photo evidence and map coordinates, lets barangay officials review and resolve them with proof photos, and gives the system admin full oversight with statistics and user management.

## Quick Start

```bash
cd citisense
flutter pub get
flutter run       # runs with mock data, no backend needed
```

Demo accounts (mock mode):
| Role | Email | Password |
|------|-------|----------|
| Citizen | `citizen@citisense.com` | `password` |
| Officer | `officer@citisense.com` | `password` |
| Admin | `admin@citisense.com` | `password` |

## Repository Structure

```
.
├── README.md              # this file
├── AGENTS.md              # agent instructions (session bootstrap, conventions)
├── .githooks/             # pre-commit hook (credential leak guard)
├── .gitignore
├── deploy.sh              # one-command APK build + install (see DEPLOY_INSTRUCTIONS.md)
├── build-release.sh       # APK build only
├── manage.sh              # unified project manager (app + ML + tests)
├── session-start.sh       # prints handoff + project context from Obsidian vault
├── DEPLOY_INSTRUCTIONS.md # detailed manual deploy guide
├── flutter-commands.md    # cheat sheet for common Flutter commands
├── citisense/             # Flutter + Dart app (see its README for full details)
└── ml/                    # Python ML/NLP pipeline (Naive Bayes, TF-IDF, dataset)
```

## Project Layout

### `citisense/` — The Flutter App

| Concern | Tech |
|---------|------|
| Language / UI | Dart, Flutter (Material 3, light civic design) |
| Maps | `flutter_map` + OpenStreetMap |
| Location | `geolocator` |
| Camera | `image_picker` + `permission_handler` |
| State | `provider` (ChangeNotifier) |
| Charts | `fl_chart` |
| Backend | Firebase (Auth + Firestore + Storage) |
| Video | Cloudinary (unsigned upload + signed delivery URLs) |
| Remote Config | `firebase_remote_config` (version check) |
| APK Install | `open_filex` (auto-install updates) |
| Font | Public Sans |

**Architecture:** Repository pattern — runs fully offline with `MockRepository` by default, switchable to `FirebaseRepository` with one flag (`--dart-define=USE_FIREBASE=true`).

**Full documentation:** see [`citisense/README.md`](citisense/README.md) for features, Firebase setup, Firestore schema, testing status, and build instructions.

### `ml/` — Machine Learning Pipeline

Naive Bayes + TF-IDF sentiment classification for civic complaint descriptions.

```bash
cd ml
uv venv
source .venv/bin/activate
uv sync
python benchmark.py     # evaluate model
python train_nb.py      # retrain
```

## Testing

```bash
cd citisense
flutter analyze    # clean — no issues
flutter test       # 70 unit/widget tests pass
```

See [`citisense/docs/testing.md`](citisense/docs/testing.md) for the full testing guide.

## Releases

Releases are published to **GitHub Releases**. The APK URL is consumed by Firebase Remote Config for in-app update prompts.

See [`citisense/README.md#github-release--auto-update`](citisense/README.md#github-release--auto-update) for the Remote Config parameter table.

## License

Built as the **Software Engineering 2** project at university. See [`citisense/docs/PRIVACY_POLICY.md`](citisense/docs/PRIVACY_POLICY.md) for privacy details.