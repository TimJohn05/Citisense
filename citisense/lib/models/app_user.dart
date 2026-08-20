import 'user_role.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final String? barangay;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.barangay,
    this.isActive = true,
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    UserRole? role,
    String? barangay,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      barangay: barangay ?? this.barangay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.name,
      'barangay': barangay,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.citizen,
      ),
      barangay: map['barangay'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
