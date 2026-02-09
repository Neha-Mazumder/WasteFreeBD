/// User role enumeration
enum UserRole {
  admin('admin'),
  management('management'),
  accountant('accountant'),
  user('user');

  final String value;
  const UserRole(this.value);

  /// Get role from string
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.management:
        return 'Management';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.user:
        return 'User';
    }
  }
}

/// User model representing an authenticated user
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  /// Create from database JSON
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'user'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.value,
        'created_at': createdAt.toIso8601String(),
      };

  /// Create a copy with modified fields
  AuthUser copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
