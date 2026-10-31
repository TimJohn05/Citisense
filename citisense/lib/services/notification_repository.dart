import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/notification_model.dart';
import '../models/enums.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  // Lazily resolved so the singleton can be referenced without triggering
  // Firebase initialization in mock mode (tests, offline builds).
  FirebaseFirestore? _db;
  FirebaseFirestore get db {
    if (_db == null) {
      try {
        _db = FirebaseFirestore.instance;
      } catch (_) {
        rethrow;
      }
    }
    return _db!;
  }

  Box<AppNotification>? _localBox;
  bool _initialized = false;

  static const String _boxName = 'notifications';

  bool get _firebaseAvailable {
    if (_db != null) return true;
    try {
      _db = FirebaseFirestore.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter().timeout(
        const Duration(seconds: 2),
        onTimeout: () async => throw TimeoutException('Hive init timed out'),
      );
      Hive.registerAdapter(AppNotificationAdapter());
      _localBox = await Hive.openBox<AppNotification>(_boxName);
      _initialized = true;
    } catch (_) {
      // Hive unavailable in test/headless environment — notifications
      // degrade to local-only (no persistence).
      _initialized = true;
    }
  }

  Stream<List<AppNotification>> watchNotifications(String userId) {
    if (!_firebaseAvailable) {
      return Stream.value(getLocalNotifications(userId));
    }

    final firestoreStream = db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    });

    // Merge with local cache
    return firestoreStream.asyncMap((firestoreNotifications) async {
      final localNotifications = getLocalNotifications(userId);
      final allNotifications = <AppNotification>[];

      final localMap = {for (var n in localNotifications) n.id: n};
      for (var n in firestoreNotifications) {
        allNotifications.add(n);
        localMap.remove(n.id);
      }
      allNotifications.addAll(localMap.values);

      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allNotifications;
    });
  }

  List<AppNotification> getLocalNotifications(String userId) {
    if (_localBox == null) return [];
    return _localBox!.values
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveNotification(AppNotification notification) async {
    if (!_initialized) await initialize();

    if (_firebaseAvailable) {
      await db
          .collection('users')
          .doc(notification.userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    }

    if (_localBox != null) {
      await _localBox!.put(notification.id, notification);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (!_initialized) await initialize();

    final notification = _localBox?.get(notificationId);
    if (notification != null) {
      final updated = notification.copyWith(isRead: true);
      await _localBox?.put(notificationId, updated);

      if (_firebaseAvailable) {
        await db
            .collection('users')
            .doc(notification.userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    }
  }

  Future<void> markAllAsRead(String userId) async {
    if (!_initialized) await initialize();

    final notifications = getLocalNotifications(userId);
    for (final notification in notifications) {
      if (!notification.isRead) {
        await markAsRead(notification.id);
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (!_initialized) await initialize();

    final notification = _localBox?.get(notificationId);
    if (notification != null) {
      await _localBox?.delete(notificationId);

      if (_firebaseAvailable) {
        await db
            .collection('users')
            .doc(notification.userId)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    }
  }

  Future<int> getUnreadCount(String userId) async {
    if (!_initialized) await initialize();

    if (_localBox == null) return 0;

    return _localBox!.values
        .where((n) => n.userId == userId && !n.isRead)
        .length;
  }

  Future<void> saveAllLocal(List<AppNotification> notifications) async {
    if (!_initialized) await initialize();
    if (_localBox == null) return;
    for (final n in notifications) {
      await _localBox!.put(n.id, n);
    }
  }
}

// Hive Adapter for AppNotification
class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 42;

  @override
  AppNotification read(BinaryReader reader) {
    return AppNotification(
      id: reader.readString(),
      userId: reader.readString(),
      complaintId: reader.readString(),
      oldStatus: ComplaintStatus.values.byName(reader.readString()),
      newStatus: ComplaintStatus.values.byName(reader.readString()),
      title: reader.readString(),
      body: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isRead: reader.readBool(),
      customMessage: reader.readString() == 'null' ? null : reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.complaintId);
    writer.writeString(obj.oldStatus.name);
    writer.writeString(obj.newStatus.name);
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isRead);
    writer.writeString(obj.customMessage ?? 'null');
  }
}
