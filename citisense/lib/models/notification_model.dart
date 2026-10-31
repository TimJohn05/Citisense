import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';

class AppNotification {
  final String id;
  final String userId;
  final String complaintId;
  final ComplaintStatus oldStatus;
  final ComplaintStatus newStatus;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? customMessage;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.complaintId,
    required this.oldStatus,
    required this.newStatus,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.customMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'complaintId': complaintId,
      'oldStatus': oldStatus.name,
      'newStatus': newStatus.name,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'customMessage': customMessage,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      complaintId: map['complaintId'] as String,
      oldStatus: ComplaintStatus.values.byName(map['oldStatus'] as String),
      newStatus: ComplaintStatus.values.byName(map['newStatus'] as String),
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
      customMessage: map['customMessage'] as String?,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? complaintId,
    ComplaintStatus? oldStatus,
    ComplaintStatus? newStatus,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? customMessage,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      complaintId: complaintId ?? this.complaintId,
      oldStatus: oldStatus ?? this.oldStatus,
      newStatus: newStatus ?? this.newStatus,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      customMessage: customMessage ?? this.customMessage,
    );
  }
}