import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../constants/user_roles.dart';

/// 인증 서비스 - Firestore 기반 로그인
class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 이메일과 비밀번호로 로그인
  Future<AppUser> login(String email, String password) async {
    try {
      print('🔵 로그인 시도: $email');

      // Firestore에서 사용자 찾기
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        throw Exception('등록되지 않은 이메일입니다');
      }

      final userDoc = usersSnapshot.docs.first;
      final userData = userDoc.data();

      // 비밀번호 확인
      if (userData['password'] != password) {
        throw Exception('비밀번호가 일치하지 않습니다');
      }

      // 계정 상태 확인
      if (userData['status'] != 'ACTIVE') {
        throw Exception('비활성화된 계정입니다');
      }

      print('✅ 로그인 성공: ${userData['name']} (${userData['role']})');

      // User 객체 생성
      return AppUser(
        id: userData['id'],
        organizationId: userData['organization_id'] ?? '',
        name: userData['name'],
        email: userData['email'],
        role: _parseUserRole(userData['role']),
        phone: userData['phone'],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ 로그인 실패: $e');
      rethrow;
    }
  }

  /// 역할 문자열을 UserRole enum으로 변환
  UserRole _parseUserRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'CENTER_ADMIN':
        return UserRole.centerAdmin;
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'THERAPIST':
        return UserRole.therapist;
      case 'GUARDIAN':
        return UserRole.guardian;
      case 'DOCTOR':
        return UserRole.doctor;
      default:
        return UserRole.therapist;
    }
  }
}
