import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<void> showNotification(AppNotification notification) async {
    if (!_initialized) await initialize();
    // Local system notifications require the flutter_local_notifications
    // package, which is incompatible with AGP 9.0's new DSL (core library
    // desugaring cannot be configured). Add it back to pubspec.yaml and
    // resolve the AGP desugaring config when push notifications are needed
    // in Firebase mode. Until then, notifications are stored in Hive locally.
  }

  Future<void> cancelNotification(int id) async {}

  Future<void> cancelAllNotifications() async {}
}

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
