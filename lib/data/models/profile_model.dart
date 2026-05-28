class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  bool get isSuperadmin => role == 'superadmin';

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get initials {
    final parts = displayName.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? '',
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  ProfileModel copyWith({
    String? fullName,
    String? role,
    bool? isActive,
  }) =>
      ProfileModel(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'role': role,
        'is_active': isActive,
      };
}
