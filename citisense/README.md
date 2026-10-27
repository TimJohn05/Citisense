# CitiSense

**Urban feedback & resolution platform for Barangays of Calamba City, Laguna** — built with Flutter + Dart.

CitiSense lets citizens report community issues (waste, roads, water, lighting) with a
photo and map coordinates, lets barangay officials review and resolve them **with photo
proof**, and gives the system admin full oversight with statistics and user management.

> Built as the Software Engineering 2 project. This replaces the earlier web/PWA
> prototype (Capacitor + Vite). The professor required a native app, so everything is
> written in **Dart with Flutter** — no PWA.

---

## Features

### Citizen / User
- Sign up & sign in.
- **Forgot password** with email validation (RFC 5322 regex).
- File a complaint: choose a category, describe the issue, **capture an evidence photo**
  (camera permission is requested before opening the camera), and **pin the exact
  location on a map** (GPS or manual drag) with live coordinates.
- **Video evidence** support (Cloudinary signed URLs for secure delivery).
- **Offline draft queue** — complaints saved locally when offline, auto-retry on reconnect.
- Instant auto-analysis: sentiment classification (Positive / Neutral / Negative) and a
  suggested action.
- Track the status of all your reports (Pending → Under Review → Resolved / **Rejected**)
  and see the official's notes and the **resolution proof photo**.
- **Rejected status** now visible in dashboard with dedicated stat card.
- **Pull-to-refresh** on complaint detail screen.
- **Persistent search & filters** across tab switches.

### Barangay Official
- Dashboard with live statistics and a **complaints-by-category chart** (x-axis shows icon + short label).
- Real-time Firestore snapshots — live dashboard updates without manual refresh.
- Review the full complaint feed with status and category filters.
- **Scrollable filter chips** with haptic feedback on tap.
- Acknowledge a report (moves it to *Under Review*).
- **Mark as Resolved** — requires resolution notes **and a proof photo** showing the
  problem has been cleared (e.g., the sidewalk trash is gone).
- Reject a report with a reason.
- **Get Directions** button (full-width, FilledButton.tonal) opens turn-by-turn navigation.
- **Offline indicator banner** when connectivity is lost.

### System Admin
- Dashboard: totals, resolution rate, complaints by status/category, sentiment pie.
- User management: add barangay official accounts, search users, revoke/restore access.
- Manage all complaints (including removal).
- **Audit logs** with search bar, sortable columns, and enhanced detail dialog showing:
  user ID, email, role, IP address, device info, metadata.
- **Remote Config version check** — non-blocking update prompt with "Update Now" button
  that downloads and installs APK directly.

---

## Tech Stack

| Concern | Choice |
| --- | --- |
| Language / UI | Dart, Flutter (Material 3, light civic design) |
| Maps | `flutter_map` + OpenStreetMap (free, no API key) |
| Location | `geolocator` (GPS coordinates) |
| Camera | `image_picker` + `permission_handler` (explicit camera permission) |
| State | `provider` (ChangeNotifier) |
| Charts | `fl_chart` |
| Backend | Firebase (Auth + Firestore + Storage) — see below |
| Video | Cloudinary (unsigned upload preset + signed delivery URLs) |
| Font | Public Sans |
| Connectivity | `connectivity_plus` (offline detection) |
| Remote Config | `firebase_remote_config` (version check) |
| APK Install | `open_filex` (auto-install updates) |

The app uses a **repository pattern**: it runs fully offline with an in-memory mock
(`MockRepository`) out of the box, and can be switched to Firebase
(`FirebaseRepository`) with one flag.

---

## Getting Started

Requirements: Flutter 3.44+ (Dart 3.12+), and Android Studio (for the APK).

```bash
cd citisense
flutter pub get
flutter run                       # runs with mock data, no backend needed
```

### Deployment Scope

Target locality: **Calamba City, Laguna, Philippines** (54 barangays). The map picker
defaults to Calamba City center (14.1956, 121.1469); demo seed data uses real Calamba
barangays (e.g. Barangay 1, Halang, Real, Canlubang) and complaint coordinates inside
the city.

**Map zoom constrained** — `minZoom: 12` (barangay level) prevents grey-screen at wide zoom.

### Demo Accounts (mock mode)

| Role | Email | Password |
| --- | --- | --- |
| Citizen | citizen@citisense.com | password |
| Barangay Official | officer@citisense.com | password |
| System Admin | admin@citisense.com | password |

---

## Database Recommendation

For a solo developer who needs something **easy to manage and easy to deploy on the
internet**, we recommend **Firebase**:

- **Auth** — email/password sign-in is built in.
- **Firestore** — NoSQL database with real-time sync; free "Spark" plan.
- **Storage** — for complaint evidence photos and resolution proof photos.
- **Remote Config** — version check without new deploy.
- **Deploy** — Firebase Hosting for web, or ship the APK; the admin console is a web UI.
- Most widely used backend in PH universities — plenty of tutorials.

Alternative: **Supabase** (PostgreSQL + Auth + Storage) if your team prefers SQL.

### Enable Firebase

The two Firebase config files are **not committed**, because each one is specific to a
single Firebase project. Templates with the expected structure are committed instead,
so a fresh clone knows exactly what to create.

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add an **Android app** with package id `com.citisense.citisense` (must match
   `android/app/build.gradle.kts`), and a **Web app** for the web build.
3. Download `google-services.json` and place it in `android/app/`.
4. Generate `lib/firebase_options.dart` (Firebase console → Project settings → Your
   apps → Web → SDK setup and configuration → copy into `lib/`).

Both files are already in `.gitignore`, so git will not track them.

To start from the committed templates instead:

```bash
cp android/app/google-services.json.example android/app/google-services.json
cp lib/firebase_options.example.dart lib/firebase_options.dart
```

Then replace every `REPLACE_WITH_...` placeholder with the value Firebase prints for
your project. Both files are required before the app can compile: `main.dart` imports
`firebase_options.dart` unconditionally, and `android/app/build.gradle.kts` only applies
the Google Services plugin when `google-services.json` exists.

### Preventing Credential Leaks

`.githooks/pre-commit` refuses commits containing an API key, private key, cloud access
token, service account key, keystore, or `.env` file, and refuses the two Firebase config
files outright. The hook is committed, but git ignores `core.hooksPath`, so enable it once
per clone:

```bash
git config core.hooksPath .githooks
```

Keeping config out of git does not make it secret. A release APK always contains the
Firebase API key, so anyone who installs it can read that key. What limits the damage is
application restrictions in Google Cloud Console (restrict the Android key to package name
plus signing certificate, restrict the Web key to HTTP referrers) and Firestore rules that
reject unauthenticated or unauthorised access. Neither is enforced by this repository.

In Firebase console enable:

- **Authentication** → Email/Password
- **Cloud Firestore**

Cloud Storage is deliberately not used for photos: since 2026-02-03 it requires the Blaze
(pay-as-you-go) plan, so evidence photos are stored as base64 data URIs inside the
Firestore document instead.

**Video evidence** is persisted via **Cloudinary** (free tier, no credit card needed):
1. Create a free account at [cloudinary.com](https://cloudinary.com).
2. In the dashboard, note your **Cloud Name**.
3. Go to Settings → Upload → Upload presets → create an **unsigned** preset.
4. **Signed URLs** are generated client-side (SHA-1) when `CLOUDINARY_API_KEY` and
   `CLOUDINARY_API_SECRET` are provided via `--dart-define`.

Run the app with:

```bash
flutter run --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset \
  --dart-define=CLOUDINARY_API_KEY=your_api_key \
  --dart-define=CLOUDINARY_API_SECRET=your_api_secret
```

Without these defines, videos are silently skipped (photos still work).

**Releases must pass the define.** Without `USE_FIREBASE=true` the app silently falls back
to `MockRepository` and shows seeded demo data instead of live data, with no warning on
screen. Build size is a quick tell: mock ≈ 66.7 MB, Firebase ≈ 69.9 MB.

```bash
flutter build apk --release \
  --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset \
  --dart-define=CLOUDINARY_API_KEY=your_api_key \
  --dart-define=CLOUDINARY_API_SECRET=your_api_secret
flutter build web --release \
  --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset \
  --dart-define=CLOUDINARY_API_KEY=your_api_key \
  --dart-define=CLOUDINARY_API_SECRET=your_api_secret
```

### Cloudinary Signed URLs

When API Key + Secret are provided, video delivery URLs are signed client-side (SHA-1 of
`public_id+version+secret`). This prevents public guessing of video URLs. Without the
secret, the app falls back to public URLs.

### Firestore Schema

- `users/{id}` — `fullName, email, role, barangay, isActive, createdAt`
- `complaints/{id}` — `citizenId, citizenName, category, description, sentiment,
  recommendation, status, officerNotes, rejectReason, latitude, longitude,
  evidenceImage, proofImage, evidenceVideos, resolvedBy, resolvedAt, createdAt`
- `logs/{id}` — `timestamp, action, detail, isSuccess, userId, userEmail, userRole,
  ipAddress, deviceInfo, metadata`

---

## Building the Android APK

Run on a machine with Android Studio / Android SDK:

```bash
cd citisense
flutter build apk --release \
  --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset \
  --dart-define=CLOUDINARY_API_KEY=your_api_key \
  --dart-define=CLOUDINARY_API_SECRET=your_api_secret
```

Output: `build/app/outputs/flutter-apk/app-release.apk` (≈ 69.9 MB with Firebase).

### One-Command Deploy (from project root)

```bash
CLOUDINARY_API_SECRET=your_secret ./deploy.sh
```

This builds, installs on connected device, and copies to `/sdcard/Citisense/`.

---

## Project Structure

```
lib/
├── main.dart                  # entry point (mock or Firebase mode)
├── app.dart                   # MaterialApp + role-based routing
├── core/theme/                # design system (colors, theme)
├── models/                    # AppUser, Complaint, enums, SystemLog
├── services/                  # sentiment engine, location, camera, repositories, version check
├── state/                     # AppState (ChangeNotifier)
├── widgets/                   # shared widgets (chips, cards, map, photo picker, skeleton, offline indicator)
└── screens/
    ├── auth/                  # login, signup
    ├── citizen/               # home, report issue, my reports
    ├── officer/               # dashboard, complaints feed, navigation
    ├── admin/                 # dashboard, users, complaints, logs
    └── complaint_detail_screen.dart   # shared detail + role actions
```

---

## Testing

See [`docs/testing.md`](docs/testing.md): automated checks (`flutter analyze` /
`flutter test`), on-device install commands, and a manual test matrix for all three
roles across light/dark themes.

**Current status:**
- `flutter analyze` — Clean (no issues)
- `flutter test` — **70/70 unit tests pass** (boot, auth, report flow, NB/TF-IDF, sentiment, compass, dashboard nav, session expiry, admin logs)
- `flutter test integration_test` — **11/11 integration tests pass** (error handling, citizen→officer→admin flow)

---

## Docs for the Paper

Diagrams and documents for the SE2 paper (DFDs, use case, Gantt, architecture,
mermaid sources) are copied into [`docs/`](docs/). The original prototype and style
guide are in the project backup (Figma files).

## GitHub Release & Auto-Update

Releases are published to **GitHub Releases**. The APK URL is used by the
**Remote Config version check**:

```bash
gh release create v1.0.1 build/app/outputs/flutter-apk/app-release.apk \
  --title "CitiSense v1.0.1" \
  --notes "Release notes..."
```

In Firebase Console → **Remote Config**, set:
| Parameter | Example Value |
|-----------|---------------|
| `min_app_version` | `1.0.0` |
| `latest_app_version` | `1.0.1` |
| `update_apk_url` | `https://github.com/TimJohn05/Citisense/releases/download/v1.0.1/app-release.apk` |
| `update_notes` | `Fixed map zoom, offline drafts, real-time updates, signed videos` |

The app checks on startup and shows a non-blocking "Update Now" button that
downloads and installs the APK directly.