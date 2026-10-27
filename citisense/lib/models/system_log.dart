class SystemLog {
  final String id;
  final DateTime timestamp;
  final String action;
  final String detail;
  final bool isSuccess;
  final String? userId;
  final String? userEmail;
  final String? userRole;
  final String? ipAddress;
  final String? deviceInfo;
  final Map<String, dynamic>? metadata;

  const SystemLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.detail,
    this.isSuccess = true,
    this.userId,
    this.userEmail,
    this.userRole,
    this.ipAddress,
    this.deviceInfo,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'detail': detail,
      'isSuccess': isSuccess,
      'userId': userId,
      'userEmail': userEmail,
      'userRole': userRole,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'metadata': metadata,
    };
  }

  factory SystemLog.fromMap(Map<String, dynamic> map) {
    return SystemLog(
      id: map['id'] as String,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      action: map['action'] as String,
      detail: map['detail'] as String,
      isSuccess: map['isSuccess'] as bool? ?? true,
      userId: map['userId'] as String?,
      userEmail: map['userEmail'] as String?,
      userRole: map['userRole'] as String?,
      ipAddress: map['ipAddress'] as String?,
      deviceInfo: map['deviceInfo'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
