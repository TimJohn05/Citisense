class SystemLog {
  final String id;
  final DateTime timestamp;
  final String action;
  final String detail;
  final bool isSuccess;

  const SystemLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.detail,
    this.isSuccess = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'detail': detail,
      'isSuccess': isSuccess,
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
    );
  }
}
