import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/user_roles.dart';

/// 사용자 모델
class AppUser {
  final String id;
  final String organizationId;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? profileImageUrl;
  final List<String> permissions;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.organizationId,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.permissions = const [],
    required this.createdAt,
  });

  /// Firestore에서 읽어오기
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      organizationId: data['organization_id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: UserRoleExtension.fromString(data['role'] as String? ?? 'GUARDIAN'),
      phone: data['phone'] as String?,
      profileImageUrl: data['profile_image_url'] as String?,
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore에 저장하기
  Map<String, dynamic> toFirestore() {
    return {
      'organization_id': organizationId,
      'email': email,
      'name': name,
      'role': role.value,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'permissions': permissions,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// 복사본 생성 (일부 필드 변경)
  AppUser copyWith({
    String? organizationId,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? profileImageUrl,
    List<String>? permissions,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id,
      organizationId: organizationId ?? this.organizationId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
