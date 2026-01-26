import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

/// 환자/대상자 모델
class Patient {
  final String id;
  final String organizationId;
  final String patientCode; // 센터 내 고유 코드
  final String name;
  final DateTime birthDate;
  final String gender; // 'M', 'F', 'OTHER'
  final List<String> diagnosis; // 진단명 리스트
  final List<String> guardianIds; // 보호자 ID 리스트
  final String assignedTherapistId; // 담당 치료사 ID
  final Map<String, dynamic>? medicalHistory; // 의료 이력
  final Map<String, dynamic>? emergencyContact; // 응급 연락처
  final PatientStatus status;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.organizationId,
    required this.patientCode,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.diagnosis = const [],
    this.guardianIds = const [],
    required this.assignedTherapistId,
    this.medicalHistory,
    this.emergencyContact,
    this.status = PatientStatus.active,
    required this.createdAt,
  });

  /// Firestore에서 읽어오기
  factory Patient.fromFirestore(Map<String, dynamic> data, String id) {
    return Patient(
      id: id,
      organizationId: data['organization_id'] as String? ?? '',
      patientCode: data['patient_code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      birthDate: (data['birth_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'] as String? ?? 'OTHER',
      diagnosis: List<String>.from(data['diagnosis'] as List? ?? []),
      guardianIds: List<String>.from(data['guardian_ids'] as List? ?? []),
      assignedTherapistId: data['assigned_therapist_id'] as String? ?? '',
      medicalHistory: data['medical_history'] as Map<String, dynamic>?,
      emergencyContact: data['emergency_contact'] as Map<String, dynamic>?,
      status: _parsePatientStatus(data['status'] as String?),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore에 저장하기
  Map<String, dynamic> toFirestore() {
    return {
      'organization_id': organizationId,
      'patient_code': patientCode,
      'name': name,
      'birth_date': Timestamp.fromDate(birthDate),
      'gender': gender,
      'diagnosis': diagnosis,
      'guardian_ids': guardianIds,
      'assigned_therapist_id': assignedTherapistId,
      'medical_history': medicalHistory,
      'emergency_contact': emergencyContact,
      'status': status.value,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// 나이 계산
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 환자 상태 파싱
  static PatientStatus _parsePatientStatus(String? status) {
    switch (status) {
      case 'ACTIVE':
        return PatientStatus.active;
      case 'INACTIVE':
        return PatientStatus.inactive;
      case 'DISCHARGED':
        return PatientStatus.discharged;
      default:
        return PatientStatus.active;
    }
  }

  /// 복사본 생성
  Patient copyWith({
    String? organizationId,
    String? patientCode,
    String? name,
    DateTime? birthDate,
    String? gender,
    List<String>? diagnosis,
    List<String>? guardianIds,
    String? assignedTherapistId,
    Map<String, dynamic>? medicalHistory,
    Map<String, dynamic>? emergencyContact,
    PatientStatus? status,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id,
      organizationId: organizationId ?? this.organizationId,
      patientCode: patientCode ?? this.patientCode,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      diagnosis: diagnosis ?? this.diagnosis,
      guardianIds: guardianIds ?? this.guardianIds,
      assignedTherapistId: assignedTherapistId ?? this.assignedTherapistId,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
