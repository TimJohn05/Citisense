# CitiSense Code Review Guide

A plain-English walkthrough of every file in the app and how they connect.
Read this to understand what the code does before touching it.

---

## Project Structure

```
lib/
├── main.dart                 ← app entry point
├── app.dart                  ← root widget, routing, theming
├── core/theme/               ← colors, fonts, Material 3 theme
├── models/                   ← data shapes (Complaint, User, enums)
├── services/                 ← business logic (repository, sentiment, camera, location)
├── state/                    ← central app state (Provider)
├── screens/                  ← full pages the user sees
│   ├── auth/                 ← login, signup
│   ├── citizen/              ← citizen role (home, report, my reports)
│   ├── officer/              ← officer role (dashboard, complaints)
│   ├── admin/                ← admin role (dashboard, users, complaints, logs)
│   └── settings/             ← theme toggle, privacy policy
└── widgets/                  ← reusable UI pieces (cards, chips, buttons)
```

---

## 1. Entry Point

### `main.dart`
The very first code that runs. It does two things:
1. Initializes Firebase (if `USE_FIREBASE=true` was passed at build time) or
   creates a `MockRepository` (the default offline demo mode).
2. Calls `runApp()` with the `App` widget.

**Key idea**: The app can run with zero internet. Firebase is optional.

### `app.dart`
The root widget. It:
- Sets up `ChangeNotifierProvider<AppState>` — this gives every screen
  access to the shared app state (logged-in user, complaints list, etc.).
- Applies the current theme (light/dark/high-contrast) by calling
  `AppColors.apply()` once, then building `MaterialApp` with the right
  `theme` and `darkTheme`.
- Contains `AuthGate`, a widget that watches `AppState.user` and routes
  to the correct screen:
  - `null` → LoginScreen
  - `UserRole.citizen` → CitizenShell
  - `UserRole.officer` → OfficerShell
  - `UserRole.admin` → AdminShell

**Key idea**: No manual `Navigator.push` for login/logout. The app
automatically shows the right screen based on who is logged in.

---

## 2. Theme System (`core/theme/`)

### `app_colors.dart`
Defines ALL the colors the app uses, organized into palettes:
- `AppPalette.light` — the default light palette
- `AppPalette.lightHighContrast` — stronger borders, bolder text
- `AppPalette.dark` — dark mode palette
- `AppPalette.darkHighContrast` — dark + high contrast

`AppColors` is a class with **static getters** (like `AppColors.primary`,
`AppColors.background`, `AppColors.textPrimary`). When the theme changes,
`AppColors.apply(newPalette)` swaps which palette those getters read from.

**Why this matters**: Every widget uses `AppColors.primary` instead of
hardcoded `Color(0xFF0F62A8)`. This means changing the theme instantly
updates every widget — no need to rebuild.

**Rule**: Never use `const` on widgets that reference `AppColors.*`,
because the color can change at runtime.

### `app_theme.dart`
Builds the `ThemeData` objects that Flutter's Material system needs.
- `AppTheme.themeFor(dark: false, highContrast: false)` → a complete
  `ThemeData` with the right colors, fonts (Public Sans), button styles,
  card styles, etc.
- Used once in `app.dart` to set `theme:` and `darkTheme:`.

---

## 3. Data Models (`models/`)

### `complaint.dart`
The most important model. Represents one citizen report:
- **id** — unique string (UUID)
- **citizenId** / **citizenName** — who filed it
- **category** — which of the 11 civic categories (waste, road, water, etc.)
- **description** — what the citizen wrote
- **sentiment** — auto-analyzed as positive/negative/neutral
- **recommendation** — auto-generated advice based on category + sentiment
- **status** — `pending` → `inReview` → `resolved` or `rejected`
- **lat/lng** — map coordinates
- **evidenceImage** — photo the citizen uploaded
- **proofImage** — photo the officer uploaded when resolving
- **officerNotes** / **rejectReason** — officer's comments

Has `toMap()` and `fromMap()` for converting to/from Firestore documents
and `copyWith()` for making modified copies (important for immutable state).

### `app_user.dart`
Represents any user (citizen, officer, or admin):
- **id**, **fullName**, **email**, **password** (stored in mock; Firebase
  uses FirebaseAuth instead)
- **role** — `UserRole.citizen`, `UserRole.officer`, or `UserRole.admin`
- **barangay** — which Calamba barangay they belong to
- **isActive** — admin can revoke access

### `enums.dart`
Defines the app's domain constants:
- **ComplaintCategory** — 11 values: `waste`, `road`, `water`, `lighting`,
  `peaceOrder`, `trafficObstruction`, `floodDrainage`, `healthSanitation`,
  `electricalHazard`, `publicFacilities`, `generalInquiry`. Each has a
  display `label`, `shortLabel`, Material `icon`, `color`, and `mlKey`
  (snake_case for the ML model).
- **ComplaintStatus** — `pending`, `inReview`, `resolved`, `rejected`.
  Each has a label and color.
- **Sentiment** — `negative`, `neutral`, `positive`. Each has a label
  and color.

These enums have **extension methods** (like `.label`, `.icon`, `.color`)
so screens can do `complaint.status.label` instead of writing switch
statements everywhere.

### `user_role.dart`
`UserRole` enum with `citizen`, `officer`, `admin`. Each has a display
label, icon, and color used in the UI.

### `system_log.dart`
A simple audit log entry: timestamp, action description, detail text,
success/failure flag. Used by the admin logs screen.

---

## 4. Services (`services/`)

### `repository.dart` (abstract interface)
Defines the **contract** — what operations are possible:
- `login(email, password)` → `AppUser?`
- `signup(name, email, password, barangay)` → `AppUser?`
- `getComplaints()`, `addComplaint()`, `updateComplaint()`, `deleteComplaint()`
- `getUsers()`, `addUser()`, `updateUser()`
- `getLogs()`, `addLog()`
- `uploadImage(path)` → `String` (URL or local path)

No actual code — just the function signatures. This is the
**Repository Pattern**: the app talks to an interface, not a
specific implementation.

### `mock_repository.dart`
The **default** implementation. Works 100% offline with in-memory data:
- Pre-seeds 5 demo users, 10 complaints (one per Calamba category), and
  3 system logs.
- Simulates network delay with `Future.delayed(Duration(milliseconds: 300))`.
- Images are stored as file paths (local).
- No internet needed. Perfect for demos and testing.

### `firebase_repository.dart`
The **real** implementation using Google Firebase:
- **FirebaseAuth** — handles login/signup/password.
- **Cloud Firestore** — stores complaints, users, and logs as documents
  in collections.
- **Firebase Storage** — stores uploaded photos (evidence + proof).
- **UUID** — generates unique IDs for new documents.
- Enabled only when built with `--dart-define=USE_FIREBASE=true` AND
  `google-services.json` is in place.

**Key idea**: Both implementations have the same methods. The rest of
the app doesn't know or care which one it's using. This makes it easy
to switch between demo mode and production.

### `sentiment_engine.dart`
A rule-based Taglish (Tagalog + English) sentiment analyzer:
1. Tokenizes the input text into words.
2. Strips Tagalog particles (`po`, `naman`, `kasi`, `lang`, etc.)
   so they don't skew the result.
3. Checks for negation in the previous meaningful token
   (`hindi naman mabaho` → the negation flips to positive).
4. Matches against phrase lists (longer matches first) and word lists.
5. Returns a `SentimentResult` with the sentiment label, a confidence
   score (0.0–1.0), and an auto-generated recommendation based on the
   complaint category.

**Why not ML?** A real ML model is documented in `docs/sentiment-service.md`
but deliberately NOT wired — the app works fully offline with this
lexicon engine. The ML model can be added later.

### `camera_service.dart`
Wraps the `image_picker` and `permission_handler` packages:
- `capturePhoto()` — requests camera permission, opens the camera, returns
  a file path or null.
- `pickFromGallery()` — opens the photo gallery picker.

### `location_service.dart`
Wraps the `geolocator` package:
- `checkPermission()` — checks if location permission is granted.
- `requestPermission()` — prompts the user.
- `getCurrentPosition()` — returns the device's GPS coordinates as `LatLng`.

---

## 5. State Management (`state/`)

### `app_state.dart`
The **brain** of the app. A single `ChangeNotifier` that holds ALL
shared state and business logic:

**What it holds:**
- `user` — the currently logged-in `AppUser` (or null)
- `complaints` — list of all complaints
- `users` — list of all users (admin manages these)
- `logs` — list of system audit logs
- `themeStyle` / `highContrast` — persisted theme preferences
- `isLoading` / `error` — UI feedback state

**What it does:**
- `login()` / `signup()` / `logout()` — authentication
- `submitComplaint()` — creates a complaint, runs sentiment analysis,
  saves to the repository
- `acknowledgeComplaint()` / `resolveComplaint()` / `rejectComplaint()`
  — status transitions (officer actions)
- `addOfficer()` / `toggleUserActive()` / `deleteComplaint()` — admin
  actions
- `setThemeStyle()` / `setHighContrast()` — theme changes
- `refresh()` — reloads all data from the repository

**How screens use it:**
```dart
final appState = context.watch<AppState>();  // rebuilds when state changes
appState.user;          // current user
appState.complaints;    // all complaints
appState.submitComplaint(...);  // business logic
```

---

## 6. Screens (`screens/`)

### Auth screens

**`login_screen.dart`** — Email/password form, "Sign In" button, expandable
demo-credentials card (tap to see citizen/officer/admin accounts and auto-fill),
link to signup, and a Privacy Policy link.

**`signup_screen.dart`** — Name, email, password, confirm-password form for
citizen registration. Officers are added by the admin.

### Citizen screens

**`citizen_shell.dart`** — Bottom navigation bar with 3 tabs:
Home | Report | My Reports. Uses `IndexedStack` so tab state is preserved.

**`citizen_home_screen.dart`** — Welcome message, "Report an Issue" CTA card,
mini stat cards (total/pending/resolved), and a list of the 3 most recent
reports. Has LogoutButton and SettingsButton in the AppBar.

**`report_issue_screen.dart`** — The main complaint submission form:
1. Category picker (11 options as chips)
2. Description text area
3. Photo picker (camera or gallery)
4. Location picker (map with crosshair + pin button + GPS button)
5. "Submit" button — blocked if no photo or location

After submission, shows `_SubmissionResultScreen` with the auto-analyzed
sentiment (color-coded badge) and recommendation text.

**`my_reports_screen.dart`** — Filterable list of the citizen's own complaints.
Filter chips at the top for each status. Tapping a complaint opens
`ComplaintDetailScreen`.

### Officer screens

**`officer_shell.dart`** — Bottom navigation with 2 tabs: Dashboard | Complaints.

**`officer_dashboard_screen.dart`** — Stat cards (total/pending/in-review/resolved),
a bar chart of complaints by category (using `fl_chart`), and a recent
complaints list.

**`officer_complaints_screen.dart`** — All complaints with dual filter rows:
status chips on top, category chips below. Tapping opens detail screen.

### Admin screens

**`admin_shell.dart`** — Bottom navigation with 4 tabs: Dashboard | Users |
Complaints | Logs.

**`admin_dashboard_screen.dart`** — System-wide stats, a status bar chart,
category breakdown with progress bars, and a sentiment pie chart.

**`admin_users_screen.dart`** — Searchable user list, "Add Officer" bottom
sheet, and per-user toggle to revoke/restore access.

**`admin_complaints_screen.dart`** — All complaints with status filter chips.

**`admin_logs_screen.dart`** — Audit log viewer with timestamps and
success/failure indicators.

### Settings screens

**`settings_screen.dart`** — Theme selector (System/Light/Dark segmented
button), high-contrast toggle, About section with app description, and
Privacy Policy link.

**`privacy_policy_screen.dart`** — 8-section privacy policy explaining
camera and location permission usage.

### Shared screen

**`complaint_detail_screen.dart`** — Used by all three roles. Shows:
- Status timeline (pending → in review → resolved/rejected)
- Evidence photo (tap to zoom)
- Map preview with the complaint coordinates
- Officer notes and reject reason (if any)
- Proof photo (if resolved)
- Role-specific action buttons at the bottom:
  - Officer: Acknowledge, Resolve (with proof photo required), Reject
  - Admin: Delete

---

## 7. Reusable Widgets (`widgets/`)

These are small, focused UI pieces used across multiple screens:

| Widget | What it does |
|---|---|
| `CsLogo` | The app icon (rounded square with `location_city` icon) |
| `StatCard` | Displays a number + label + icon (used on dashboards) |
| `ComplaintCard` | Tappable card showing a complaint summary with chips |
| `StatusChip` | Colored badge for pending/in-review/resolved/rejected |
| `CategoryChip` | Colored badge for the 11 complaint categories |
| `SentimentBadge` | Colored badge for negative/neutral/positive |
| `EmptyState` | Placeholder shown when a list has no items |
| `PhotoPicker` | Tap-to-add photo widget with camera/gallery choice |
| `AppImage` | Universal image display (network, file, or placeholder) |
| `StaticMapPreview` | Non-interactive map with a single marker (for detail screens) |
| `LocationPicker` | Interactive map picker with crosshair + pin + GPS buttons |
| `LogoutButton` | Icon that shows a confirmation dialog before signing out |
| `SettingsButton` | Icon that navigates to the Settings screen |

---

## 8. How Data Flows

```
User taps "Submit"
  → ReportIssueScreen calls appState.submitComplaint(...)
    → AppState calls SentimentEngine.analyze(description)
    → AppState calls repository.addComplaint(complaint)
      → MockRepository stores in-memory list
         OR FirebaseRepository writes to Firestore
    → AppState notifies listeners (notifyListeners())
      → All widgets watching AppState rebuild with new data
```

```
User taps "Login"
  → LoginScreen calls appState.login(email, password)
    → AppState calls repository.login(email, password)
    → AppState sets _user = result
    → AuthGate watches _user → routes to correct role shell
```

---

## 9. Key Concepts to Know

**Provider / ChangeNotifier**: The app uses the `provider` package for
state management. `AppState` extends `ChangeNotifier` — when it calls
`notifyListeners()`, every widget using `context.watch<AppState>()`
automatically rebuilds with the new data. Think of it as a broadcast
system: state changes → UI updates.

**Repository Pattern**: The app never directly calls Firebase or manipulates
lists. It calls methods on `AppRepository` (the abstract interface).
`MockRepository` and `FirebaseRepository` both implement it. This means
you can swap the entire backend by changing one line in `main.dart`.

**IndexedStack**: Used in the shell screens (citizen/officer/admin) to
keep tab state alive when switching between bottom navigation tabs.
The currently selected tab's widget is shown; others stay mounted but hidden.

**Immutable models**: All models (`Complaint`, `AppUser`, `SystemLog`)
are immutable. To change something, you call `copyWith()` which returns
a new instance. This prevents bugs where a screen accidentally mutates
shared state.

**compile-time flags**: `--dart-define=USE_FIREBASE=true` is a
compile-time flag checked in `main.dart`. It determines whether to
initialize Firebase or use MockRepository. This is NOT a runtime toggle.

**Theme system**: `AppColors` uses static getters that read from a
swappable palette. When the user toggles dark mode in Settings,
`AppColors.apply(darkPalette)` is called once, and every widget reading
`AppColors.primary` etc. instantly gets the new color on next rebuild.
