// lib/models/profile.dart

enum UserRole { customer, admin, staff }

class Profile {
  final String id;
  final String? name;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.name,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: _roleFromString(json['role'] as String? ?? 'customer'),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role.name,
        'avatar_url': avatarUrl,
      };

  Profile copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }

  static UserRole _roleFromString(String role) {
    return switch (role) {
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      _ => UserRole.customer,
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isAdminOrStaff => isAdmin || isStaff;
}
