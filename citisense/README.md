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
- File a complaint: choose a category, describe the issue, **capture an evidence photo**
  (camera permission is requested before opening the camera), and **pin the exact
  location on a map** (GPS or manual drag) with live coordinates.
- Instant auto-analysis: sentiment classification (Positive / Neutral / Negative) and a
  suggested action.
- Track the status of all your reports (Pending → Under Review → Resolved / Rejected)
  and see the official's notes and the **resolution proof photo**.

### Barangay Official
- Dashboard with live statistics and a complaints-by-category chart.
- Review the full complaint feed with status and category filters.
- Acknowledge a report (moves it to *Under Review*).
- **Mark as Resolved** — requires resolution notes **and a proof photo** showing the
  problem has been cleared (e.g., the sidewalk trash is gone).
- Reject a report with a reason.

### System Admin
- Dashboard: totals, resolution rate, complaints by status/category, sentiment pie.
- User management: add barangay official accounts, search users, revoke/restore access.
- Manage all complaints (including removal).
- Audit log of system activity.

---

## Tech stack

| Concern | Choice |
| --- | --- |
| Language / UI | Dart, Flutter (Material 3, light civic design) |
| Maps | `flutter_map` + OpenStreetMap (free, no API key) |
| Location | `geolocator` (GPS coordinates) |
| Camera | `image_picker` + `permission_handler` (explicit camera permission) |
| State | `provider` (ChangeNotifier) |
| Charts | `fl_chart` |
| Backend | Firebase (Auth + Firestore + Storage) — see below |
| Font | Public Sans |

The app uses a **repository pattern**: it runs fully offline with an in-memory mock
(`MockRepository`) out of the box, and can be switched to Firebase
(`FirebaseRepository`) with one flag.

---

## Getting started

Requirements: Flutter 3.44+ (Dart 3.12+), and Android Studio (for the APK).

```bash
cd citisense
flutter pub get
flutter run                       # runs with mock data, no backend needed
```

### Deployment scope

Target locality: **Calamba City, Laguna, Philippines** (54 barangays). The map picker
defaults to Calamba City center (14.1956, 121.1469); demo seed data uses real Calamba
barangays (e.g. Barangay 1, Halang, Real, Canlubang) and complaint coordinates inside
the city.

### Demo accounts (mock mode)
| Role | Email | Password |
| --- | --- | --- |
| Citizen | citizen@citisense.com | password |
| Barangay Official | officer@citisense.com | password |
| System Admin | admin@citisense.com | password |

---

## Database recommendation

For a solo developer who needs something **easy to manage and easy to deploy on the
internet**, we recommend **Firebase**:

- **Auth** — email/password sign-in is built in.
- **Firestore** — NoSQL database with real-time sync; free "Spark" plan.
- **Storage** — for complaint evidence photos and resolution proof photos.
- **Deploy** — Firebase Hosting for web, or ship the APK; the admin console is a web UI.
- Most widely used backend in PH universities — plenty of tutorials.

Alternative: **Supabase** (PostgreSQL + Auth + Storage) if your team prefers SQL.

### Enable Firebase

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add an **Android app** with package id `com.citisense`.
3. Download `google-services.json` and place it in `android/app/`.
4. In Firebase console enable:
   - **Authentication** → Email/Password,
   - **Cloud Firestore**,
   - **Storage**.
5. Run the app with:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```

### Firestore schema

- `users/{id}` — `fullName, email, role, barangay, isActive, createdAt`
- `complaints/{id}` — `citizenId, citizenName, category, description, sentiment,
  recommendation, status, officerNotes, rejectReason, latitude, longitude,
  evidenceImage, proofImage, resolvedBy, resolvedAt, createdAt`
- `logs/{id}` — `timestamp, action, detail, isSuccess`

---

## Building the Android APK

Run on a machine with Android Studio / Android SDK:

```bash
cd citisense
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Project structure

```
lib/
├── main.dart                  # entry point (mock or Firebase mode)
├── app.dart                   # MaterialApp + role-based routing
├── core/theme/                # design system (colors, theme)
├── models/                    # AppUser, Complaint, enums, SystemLog
├── services/                  # sentiment engine, location, camera, repositories
├── state/                     # AppState (ChangeNotifier)
├── widgets/                   # shared widgets (chips, cards, map, photo picker)
└── screens/
    ├── auth/                  # login, signup
    ├── citizen/               # home, report issue, my reports
    ├── officer/               # dashboard, complaints feed
    ├── admin/                 # dashboard, users, complaints, logs
    └── complaint_detail_screen.dart   # shared detail + role actions
```

---

## Testing

See [`docs/testing.md`](docs/testing.md): automated checks (`flutter analyze` /
`flutter test`), on-device install commands, and a manual test matrix for all three
roles across light/dark themes.

---

## Docs for the paper

Diagrams and documents for the SE2 paper (DFDs, use case, Gantt, architecture,
mermaid sources) are copied into [`docs/`](docs/). The original prototype and style
guide live in the user's backup at
`/mnt/king/omarchy-backup/king/Documents/Figma/`.
