/// 사용자 역할 상수
enum UserRole {
  /// 슈퍼 관리자 (전체 시스템 관리)
  superAdmin,

  /// 센터 관리자 (센터 설정, 회원 관리)
  centerAdmin,

  /// 치료사 (환자 관리, 평가, 세션 기록)
  therapist,

  /// 보호자 (리포트 조회, 홈프로그램 수행)
  guardian,

  /// 의료진 (케이스 리뷰, 피드백)
  doctor,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.centerAdmin:
        return 'CENTER_ADMIN';
      case UserRole.therapist:
        return 'THERAPIST';
      case UserRole.guardian:
        return 'GUARDIAN';
      case UserRole.doctor:
        return 'DOCTOR';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return '슈퍼 관리자';
      case UserRole.centerAdmin:
        return '센터 관리자';
      case UserRole.therapist:
        return '치료사';
      case UserRole.guardian:
        return '보호자';
      case UserRole.doctor:
        return '의료진';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'CENTER_ADMIN':
        return UserRole.centerAdmin;
      case 'THERAPIST':
        return UserRole.therapist;
      case 'GUARDIAN':
        return UserRole.guardian;
      case 'DOCTOR':
        return UserRole.doctor;
      default:
        throw Exception('Unknown user role: $value');
    }
  }
}
