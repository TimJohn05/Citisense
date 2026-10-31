import 'package:firebase_messaging/firebase_messaging.dart';

import 'fcm_token_service.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';
import '../models/enums.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _notificationService.initialize();

    // Request permission
    await _requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Permission granted
    }
  }

  Future<void> registerUserToken(String userId) async {
    await FcmTokenService.instance.registerToken(userId);
  }

  Future<void> unregisterUserToken(String userId) async {
    await FcmTokenService.instance.removeAllTokens(userId);
  }

  void _onTokenRefresh(String token) {
    // Token refreshed, will be registered on next login
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // Show local notification when app is in foreground
      NotificationService.instance.showNotification(
        AppNotification(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: '',
          complaintId: message.data['complaintId'] ?? '',
          oldStatus: ComplaintStatus.pending,
          newStatus: ComplaintStatus.values.byName(
            message.data['newStatus'] ?? 'pending',
          ),
          title: notification.title ?? '',
          body: notification.body ?? '',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final complaintId = message.data['complaintId'];
    if (complaintId != null && complaintId.isNotEmpty) {
      // Navigation handled by app router via navigatorKey
    }
  }

  /// Send test notification (for development)
  Future<void> sendTestNotification({
    required String userId,
    required String complaintId,
    required ComplaintStatus newStatus,
    String? customMessage,
  }) async {
    // This would typically be called from Cloud Function
    // For testing, we can send directly
  }
}