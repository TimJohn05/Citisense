# SPEC: Push Notifications for Complaint Status Updates

**Status:** Ready for Agent  
**Labels:** `ready-for-agent`, `feature`, `notifications`  
**Target:** CitiSense Flutter App (Android)

---

## Problem Statement

Citizens currently have no way to know when their complaint status changes unless they manually open the app and check "My Reports." This leads to delayed awareness of resolutions, repeated follow-ups, and poor user experience. Officers and admins also lack a reliable way to notify citizens of updates without manual communication.

---

## Solution

Implement **Firebase Cloud Messaging (FCM) push notifications** for complaint status updates, with deep linking to `ComplaintDetailScreen`, in-app notification history, and full Tagalog/English localization. Notifications trigger automatically via Firestore Cloud Functions when complaint status changes.

---

## User Stories

### Citizens
1. As a **citizen**, I want to receive a push notification when my complaint status changes, so that I know immediately when action is taken.
2. As a **citizen**, I want to tap a notification and go directly to the complaint detail screen, so that I can see the full update without searching.
3. As a **citizen**, I want to see a persistent "Notifications" tab with unread badge, so that I can review past updates even if I dismissed the system notification.
4. As a **citizen**, I want notifications in my device language (Tagalog or English), so that I understand the update clearly.
5. As a **citizen**, I want to opt out of notifications in Settings, so that I control my experience.

### Officers
6. As an **officer**, I want notifications to be sent automatically when I change a complaint status, so that I don't need to manually notify citizens.
7. As an **officer**, I want the notification to include the complaint ID and new status, so that the citizen knows exactly what changed.
8. As an **officer**, I want a manual "Notify citizen" button as backup, so that I can re-send or send custom messages if needed.

### Admins
9. As an **admin**, I want to monitor notification delivery and open rates per status, so that I can measure communication effectiveness.
10. As an **admin**, I want to configure notification templates per status, so that messaging is consistent.

---

## Implementation Decisions

### Modules to Build/Modify

| Module | Type | Description |
|--------|------|-------------|
| `FirebaseMessagingService` | New | FCM token management, foreground/background message handling |
| `NotificationRepository` | New | Firestore CRUD for in-app notification history |
| `NotificationLocalDataSource` | New | Local caching of notifications (Hive/SharedPreferences) |
| `NotificationBloc/Cubit` | New | State management for in-app notification list |
| `NotificationsScreen` | New | Citizen "Notifications" tab with unread badge |
| `ComplaintDetailScreen` | Modify | Deep link handling from notification payload |
| `SettingsScreen` | Modify | Notification toggle + channel preferences |
| `FirebaseRepository` | Modify | FCM token registration on login/refresh |
| `Cloud Functions` | New | Firestore `onWrite` trigger → FCM send |

### Key Interfaces

```dart
// Notification entity
class AppNotification {
  final String id;
  final String userId;
  final String complaintId;
  final ComplaintStatus oldStatus;
  final ComplaintStatus newStatus;
  final String title;        // localized
  final String body;         // localized
  final DateTime createdAt;
  final bool isRead;
  final String? customMessage; // officer override
}

// Repository contract
abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> saveNotification(AppNotification notification);
  Future<int> getUnreadCount(String userId);
}
```

### FCM Token Management
- Auto-register token on citizen login (via `FirebaseRepository.registerFcmToken()`)
- Store token in Firestore `users/{uid}/fcmTokens/{tokenId}`
- Refresh token on `onTokenRefresh` callback
- Remove token on logout

### Notification Channels (Android)
| Channel ID | Name | Importance | Sound | Vibration |
|------------|------|------------|-------|-----------|
| `complaint_updates` | Complaint Updates | HIGH | Default | Default |

### Deep Linking
- Payload: `{"complaintId": "abc123", "type": "status_change"}`
- Route: `ComplaintDetailScreen(complaintId: payload['complaintId'])`
- Handled in `main.dart` via `FirebaseMessaging.onMessageOpenedApp`

### Localization (Tagalog + English)
| Status | English Template | Tagalog Template |
|--------|------------------|------------------|
| `pending` | "Your complaint #{id} is now Pending" | "Ang inyong reklamo #{id} ay Pending na" |
| `in_review` | "Your complaint #{id} is under review" | "Ang inyong reklamo #{id} ay nililinis na" |
| `resolved` | "Your complaint #{id} has been resolved" | "Ang inyong reklamo #{id} ay naayos na" |
| `rejected` | "Your complaint #{id} was rejected" | "Ang inyong reklamo #{id} ay tinanggihan" |
| `acknowledged` | "Your complaint #{id} acknowledged" | "Ang inyong reklamo #{id} ay nakuha na" |

**Dynamic Template:** `"Your complaint #{id} is now {status}"` + first 50 chars of description (localized)

### Cloud Function Trigger
```typescript
// functions/src/notifications.ts
export const onComplaintStatusChange = functions.firestore
  .document('complaints/{complaintId}')
  .onWrite(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || before.status === after.status) return;
    
    const userId = after.citizenId;
    const token = await getFcmToken(userId);
    if (!token) return;
    
    const payload = buildNotificationPayload(after, before.status, after.status);
    await admin.messaging().sendToDevice(token, payload);
  });
```

### Analytics (Opt-out by Default)
| Event | Fields |
|-------|--------|
| `notification_delivered` | `complaintId`, `status`, `channel` |
| `notification_opened` | `complaintId`, `status`, `channel`, `latencyMs` |
| `notification_dismissed` | `complaintId`, `status` |

Opt-out toggle in Settings → "Notification Analytics"

---

## Testing Decisions

### Unit Tests
| Module | Test Focus |
|--------|------------|
| `NotificationRepository` | CRUD, stream ordering, unread count |
| `FCMTokenManager` | Register, refresh, cleanup on logout |
| `NotificationPayloadBuilder` | Localization per status, Tagalog/English |
| `DeepLinkHandler` | Payload parsing, route navigation |

### Integration Tests
| Scenario | Steps |
|----------|-------|
| **Status change → Notification** | 1. Officer updates status in Firestore<br>2. Cloud Function triggers<br>3. FCM received on device<br>4. In-app notification appears<br>5. Tap → opens `ComplaintDetailScreen` |
| **Token Refresh** | 1. Login → token registered<br>2. Force token rotation<br>2. New token stored in Firestore |
| **Offline Queue** | 1. Disable network<br>2. Status change occurs<br>3. Re-enable network<br>4. Notification delivered |
| **Deep Link** | 1. App closed<br>2. Tap notification<br>3. App opens → `ComplaintDetailScreen` |
| **Localization** | 1. Set device to Tagalog<br>2. Receive notification<br>3. Verify Tagalog text |

### Test Artifacts
- Mock `FirebaseMessaging` via `firebase_messaging_mocks`
- Mock Firestore via `fake_cloud_firestore`
- Use existing `test/widget_test.dart` patterns

---

## Out of Scope

- iOS push notifications (APNs) — Android first
- Rich media notifications (images, actions) — MVP text only
- Grouped notifications per complaint — single notification per status change
- Officer mobile push notifications — citizen-only MVP
- Scheduled/batched notifications — immediate only
- Web push (Firebase Admin SDK only)

---

## Further Notes

- **Seam:** Single seam at `NotificationRepository` interface — all consumers (UI, Cloud Function sync) depend on this abstraction
- **Rollout:** Feature flag `enable_push_notifications` in Remote Config
- **Cost Estimate:** ~$0.10/1000 notifications (FCM free tier covers most)
- **Dependencies:** `firebase_messaging`, `flutter_local_notifications`, `hive` (local cache)
- **Permissions:** `POST_NOTIFICATIONS` (Android 13+), requested on first launch with rationale dialog
- **Migration:** Existing users get prompted for permission on next launch