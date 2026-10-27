# CitiSense — ISO/IEC 25010 expert validation checklist

Readiness map for the instrument in `docs/Validation-SE2.docx` (4-point scale: 4 Strongly Agree, 3 Agree, 2 Disagree, 1 Strongly Disagree). Indicator text below matches the instrument.

Legend: **Pass** = implemented and demonstrable, **Partial** = present with a known limitation, **Gap** = not implemented.

## A. Functional Suitability

| Indicator | Status | Where to show it |
| --- | --- | --- |
| The system classifies feedback records into positive, negative or neutral sentiment categories. | Pass | Submit a report with clearly negative, neutral, or positive wording. The result appears on the complaint detail screen and in the admin/officer sentiment chart. |
| The system allow users to filter feedback records by date, location, and data type. | Pass | Status chips, 11 Category chips (data type), Date presets (All time, Today, 7 days, 30 days), and Location (Barangay popup filter) exist on Admin Complaints, Officer Complaints, and Citizen My Reports. |
| The dashboard displays accurate counts, sentiment summaries, and urgent alerts. | Pass | Admin and Officer dashboards: live counts, status/category/sentiment charts, and the "Urgent alerts" panel (high-risk category or open more than 3 days, oldest first, tap to open). |
| The system displays counts, sentiment summaries, and urgent alerts on dashboard. | Pass | Same dashboard; counts update from Firestore after pull-to-refresh and stay consistent across roles. |

## B. Performance Efficiency

| Indicator | Status | Where to show it |
| --- | --- | --- |
| The system loads dashboard content and map data when users open the corresponding pages. | Pass | Progress indicators on sign-in, report submit, and media upload; cached map tiles through the offline tile provider; dashboards render immediately from cached state. |
| The system responds to button selections and other user actions without requiring repeated input. | Pass | Every action is single-tap; submit buttons disable while loading; haptic confirmation on login, cards, action buttons, and filter chips. |
| The system generates and displays requested reports and summaries after the user initiates the report function. | Pass | "Generate report summary" on both staff dashboards: period selector, totals, resolution rate, sentiment and category breakdown, copy to clipboard. |
| The system processes multiple user requests and feedback submissions while maintaining system responsiveness. | Partial | Firestore offline persistence, cached images, and `RepaintBoundary` charts keep the UI smooth; data is pulled on refresh rather than a live stream. |

## C. Interaction Capability

| Indicator | Status | Where to show it |
| --- | --- | --- |
| The system allows users to identify and select menus and buttons based on their displayed labels. | Pass | Labeled bottom navigation, tablet navigation rail, status/category chips, and semantic labels on cards and media controls. |
| The system allows users to follow displayed instructions and labels when performing system functions. | Pass | Inline field hints, validators, empty-state messages, and confirmation dialogs before submit, resolve, and reject. |
| The system provides navigation controls that allow users to return to previous pages and switch between available pages. | Pass | System back, app bar back, bottom navigation, and tablet navigation rail. |
| The system provides interface controls that allow users to interact with the system using mobile devices. | Pass | 44-48 dp touch targets, haptics, pinch-to-zoom photos (0.5x-4x), video play/pause/seek/replay, pull-to-refresh. |

## D. Security

| Indicator | Status | Where to show it |
| --- | --- | --- |
| The system requires valid user credentials before granting access to authorized accounts. | Pass | Firebase Authentication, suspended-account block, 2-hour session expiry, session restore only for the saved user. |
| The system masks passwords during entry so that they are not displayed in plain text. | Pass | Password fields on sign-in and sign-up are obscured, with per-field show/hide toggles. |
| The system restricts access to personal data and submitted reports to authorized users. | Pass | Firestore rules require authentication and role checks; citizens fetch only their own reports; audit logs are immutable and admin-only. |
| The system prevents sensitive information from being displayed through public links or shared pages without user authorization. | Partial | Photos are stored as base64 inside Firestore behind the rules. Video evidence sits on Cloudinary, so a copied video URL is reachable by anyone; the app never exposes that link in the UI. |

## E. Reliability

| Indicator | Status | Where to show it |
| --- | --- | --- |
| The system operates without crashing when users open and access it. | Pass | 66 unit/widget tests plus an 11-test on-device integration suite; failures surface as friendly messages, not exceptions. |
| The system performs its available functions when they are used repeatedly. | Pass | Repeat submit, pull-to-refresh, re-open, retry-after-error, and logout-while-offline flows are covered by tests. |
| The system is available when users attempt to access it. | Partial | First sign-in requires internet. After that, offline persistence keeps cached data readable and queues pending writes. |
| The system retains submitted reports and saved data without data loss. | Pass | Firestore persistence with offline queue; failed submits keep the draft and show an error; evidence uploads are retried or reported. |

## Demo script

1. Sign in as `officer@citisense.com` / `password`.
2. Tap any of the four stat cards: Complaints opens already filtered, with the matching chip selected.
3. Show the "Urgent alerts" panel and tap a row to open that complaint.
4. In Complaints, set the date filter to "Last 30 days", pick a category, and use the location filter to select a barangay (e.g. "Halang" or "Pansol").
5. Tap "Generate report summary", change the period, then "Copy summary".
6. Repeat steps 2 and 5 as `admin@citisense.com`; repeat the date/category/location filters in Citizen My Reports as `citizen@citisense.com`.

## Supplementary (named in the study's introduction, not scored in this instrument)

| Characteristic | Status | Evidence |
| --- | --- | --- |
| Compatibility | Pass | Android 7.0+ (`minSdk 24`); bottom navigation below 600 dp, navigation rail with a 1100 dp content cap above it. |
| Maintainability | Pass | Feature-first folders, shared design tokens, `flutter analyze` clean, model/service/widget/integration tests, configuration through `--dart-define` with `.example` templates. |
