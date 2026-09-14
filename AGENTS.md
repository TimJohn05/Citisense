# CitiSense SE2 Project — Agent Instructions

## First thing every session
Read the session handoff before doing anything else:

- `~/Documents/MindMap/MindMap/SE-Mindmap/Handoff.md` — current state, remaining TODO, gotchas
- `~/Documents/MindMap/MindMap/SE-Mindmap/CitiSense.md` — full project context

This Obsidian vault (`~/Documents/MindMap/MindMap/SE-Mindmap/`) is the persistent memory.
When you finish a phase, UPDATE the vault notes so the next session is accurate.

## Project
- Flutter + Dart app in `./citisense` (org `com.citisense`, app "CitiSense")
- Barangay urban-feedback app. Roles: citizen, officer, admin.
- Database: Firebase (recommended) via `FirebaseRepository`, or offline `MockRepository`.
- Default (mock) mode: `flutter run` / `flutter test` work with no setup.
- Privacy Policy included (`lib/screens/settings/privacy_policy_screen.dart`, doc copy `docs/PRIVACY_POLICY.md`).
- Logout: `LogoutButton` shows confirm dialog before signing out (used in all three role home screens).

## Commands
```bash
cd ~/SE2-Project/citisense
flutter analyze            # must be clean before finishing
flutter test               # 29 tests: boot, login/logout, report flow, NB/TF-IDF, sentiment, compass math
flutter run -d linux       # local desktop preview
flutter build apk --release  # Android APK → build/app/outputs/flutter-apk/app-release.apk
```

### Installing on phone (TECNO LJ6, `14292255AE103649`)
```bash
cd ~/SE2-Project/citisense
flutter build apk --release
~/Android/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
~/Android/platform-tools/adb shell am start -n com.citisense.citisense/.MainActivity
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/CitiSense.apk
```
APK is always also copied to `~/Desktop/CitiSense.apk` for quick sharing.

### Emulator
```bash
~/Android/emulator/emulator -avd citisense -ports 5554,5555 &
```
Requires explicit `-ports` for `adb` to register. Created AVD: `citisense` (Pixel 7, Google APIs x86_64, API 35).
Android toolchain (JDK 21 + SDK + NDK) is now fully installed on this machine — see `~/Documents/MindMap/MindMap/SE-Mindmap/Setup.md`. Note: `compileSdk = 37` is pinned in `android/app/build.gradle.kts` (permission_handler requirement).

## Bootstrapping a fresh session (one-liner)
```bash
bash ~/SE2-Project/session-start.sh
```
This prints the handoff + project status from the Obsidian vault to the terminal.

## Conventions
- Do NOT add code comments unless asked.
- Keep design tokens in `lib/core/theme/app_colors.dart`; professional civic look (see Design-System note).
- No emojis in UI; Material icons only.
- Material 3 light theme. Filled buttons, 12-16px radius, Public Sans font.
- **NEVER commit or push unless explicitly told to.** Accumulate changes, run `flutter analyze` + `flutter test` to verify, but wait for the user to say "commit" before running `git commit`. This keeps the commit history clean and avoids clutter.
