import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/patient.dart';
import '../constants/user_roles.dart';
import '../constants/enums.dart';

/// 앱 전역 상태 관리 Provider
class AppState with ChangeNotifier {
  // === 인증 상태 ===
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // === 선택된 환자 ===
  Patient? _selectedPatient;
  Patient? get selectedPatient => _selectedPatient;

  /// 로그인 설정
  void setCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  /// 로그아웃
  void logout() {
    _currentUser = null;
    _selectedPatient = null;
    notifyListeners();
  }

  /// 로딩 상태 설정
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 메시지 설정
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 선택된 환자 설정
  void setSelectedPatient(Patient? patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  /// Mock 환자 목록 가져오기 (Firebase 없이 테스트용)
  List<Patient> getMockPatients() {
    return MockDataProvider.createMockPatients();
  }

  /// 에러 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Mock 데이터 Provider (Firebase 없이 테스트용)
class MockDataProvider {
  /// Mock 사용자 생성
  static AppUser createMockTherapist() {
    return AppUser(
      id: 'therapist_001',
      organizationId: 'org_001',
      email: 'therapist@aqualab.com',
      name: '김치료',
      role: UserRole.therapist,
      phone: '010-1234-5678',
      createdAt: DateTime.now(),
    );
  }

  static AppUser createMockGuardian() {
    return AppUser(
      id: 'guardian_001',
      organizationId: 'org_001',
      email: 'guardian@aqualab.com',
      name: '박보호',
      role: UserRole.guardian,
      phone: '010-9876-5432',
      createdAt: DateTime.now(),
    );
  }

  static AppUser createMockAdmin() {
    return AppUser(
      id: 'admin_001',
      organizationId: 'org_001',
      email: 'admin@aqualab.com',
      name: '이관리',
      role: UserRole.centerAdmin,
      phone: '010-5555-6666',
      createdAt: DateTime.now(),
    );
  }

  /// Mock 환자 생성
  static List<Patient> createMockPatients() {
    return [
      Patient(
        id: 'patient_001',
        organizationId: 'org_001',
        patientCode: 'AQL-001',
        name: '홍길동',
        birthDate: DateTime(2015, 5, 15),
        gender: 'M',
        diagnosis: ['발달지연', '균형장애'],
        guardianIds: ['guardian_001'],
        assignedTherapistId: 'therapist_001',
        medicalHistory: {
          'allergies': ['없음'],
          'medications': ['없음'],
          'previousSurgeries': ['없음'],
        },
        emergencyContact: {
          'name': '박보호',
          'phone': '010-9876-5432',
          'relationship': '어머니',
        },
        status: PatientStatus.active,
        createdAt: DateTime.now(),
      ),
      Patient(
        id: 'patient_002',
        organizationId: 'org_001',
        patientCode: 'AQL-002',
        name: '김영희',
        birthDate: DateTime(2012, 3, 20),
        gender: 'F',
        diagnosis: ['뇌성마비', '근력저하'],
        guardianIds: ['guardian_002'],
        assignedTherapistId: 'therapist_001',
        medicalHistory: {
          'allergies': ['없음'],
          'medications': ['근이완제'],
          'previousSurgeries': ['없음'],
        },
        emergencyContact: {
          'name': '이보호',
          'phone': '010-1111-2222',
          'relationship': '아버지',
        },
        status: PatientStatus.active,
        createdAt: DateTime.now(),
      ),
      Patient(
        id: 'patient_003',
        organizationId: 'org_001',
        patientCode: 'AQL-003',
        name: '이철수',
        birthDate: DateTime(2018, 7, 10),
        gender: 'M',
        diagnosis: ['자폐스펙트럼', '감각통합장애'],
        guardianIds: ['guardian_003'],
        assignedTherapistId: 'therapist_001',
        medicalHistory: {
          'allergies': ['없음'],
          'medications': ['없음'],
          'previousSurgeries': ['없음'],
        },
        emergencyContact: {
          'name': '최보호',
          'phone': '010-3333-4444',
          'relationship': '어머니',
        },
        status: PatientStatus.active,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
