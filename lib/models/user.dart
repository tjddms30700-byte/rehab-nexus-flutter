import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/user_roles.dart';

/// 사용자 모델
class AppUser {
  final String id;
  final String organizationId;
  final String email;
  final String name;
  
  // ✅ 기존 단일 role (호환성 유지)
  final UserRole role;
  
  // ✅ NEW: roles Map 구조 (복수 역할 지원)
  final Map<String, bool> roles;
  
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
    this.roles = const {},
    this.phone,
    this.profileImageUrl,
    this.permissions = const [],
    required this.createdAt,
  });
  
  /// 역할 확인 헬퍼 메서드 (OR 조건)
  bool hasRole(UserRole checkRole) {
    // roles Map이 있으면 Map 사용
    if (roles.isNotEmpty) {
      final roleKey = checkRole.value.toLowerCase();
      return roles[roleKey] == true;
    }
    // 없으면 기존 단일 role 사용
    return role == checkRole;
  }
  
  /// 여러 역할 중 하나라도 있는지 확인
  bool hasAnyRole(List<UserRole> checkRoles) {
    return checkRoles.any((r) => hasRole(r));
  }
  
  /// 모든 역할을 가지고 있는지 확인
  bool hasAllRoles(List<UserRole> checkRoles) {
    return checkRoles.every((r) => hasRole(r));
  }

  /// Firestore에서 읽어오기
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    // roles Map 파싱 (신규 구조)
    Map<String, bool> rolesMap = {};
    if (data['roles'] != null && data['roles'] is Map) {
      final rawRoles = data['roles'] as Map<dynamic, dynamic>;
      rolesMap = rawRoles.map((key, value) => 
        MapEntry(key.toString().toLowerCase(), value == true)
      );
    }
    
    // 기본 role 파싱 (기존 구조 호환)
    UserRole primaryRole;
    if (data['role'] != null) {
      primaryRole = UserRoleExtension.fromString(data['role'] as String);
    } else if (rolesMap.isNotEmpty) {
      // roles Map에서 첫 번째 true인 역할을 primary로 설정
      if (rolesMap['owner'] == true || rolesMap['admin'] == true) {
        primaryRole = UserRole.centerAdmin;
      } else if (rolesMap['therapist'] == true) {
        primaryRole = UserRole.therapist;
      } else if (rolesMap['guardian'] == true) {
        primaryRole = UserRole.guardian;
      } else {
        primaryRole = UserRole.guardian;
      }
    } else {
      primaryRole = UserRole.guardian;
    }
    
    return AppUser(
      id: id,
      organizationId: data['organization_id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: primaryRole,
      roles: rolesMap,
      phone: data['phone'] as String?,
      profileImageUrl: data['profile_image_url'] as String?,
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore에 저장하기
  Map<String, dynamic> toFirestore() {
    final data = {
      'organization_id': organizationId,
      'email': email,
      'name': name,
      'role': role.value,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'permissions': permissions,
      'created_at': Timestamp.fromDate(createdAt),
    };
    
    // roles Map이 있으면 저장
    if (roles.isNotEmpty) {
      data['roles'] = roles;
    }
    
    return data;
  }

  /// 복사본 생성 (일부 필드 변경)
  AppUser copyWith({
    String? organizationId,
    String? email,
    String? name,
    UserRole? role,
    Map<String, bool>? roles,
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
      roles: roles ?? this.roles,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
