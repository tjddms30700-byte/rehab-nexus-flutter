import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

/// 환자 데이터 서비스
class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'patients';

  /// 환자 생성
  Future<String> createPatient(Patient patient) async {
    try {
      final docRef = await _firestore.collection(_collection).add(patient.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('환자 등록 실패: $e');
    }
  }

  /// 환자 조회 (ID)
  Future<Patient?> getPatient(String patientId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(patientId).get();
      if (!doc.exists) return null;
      return Patient.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('환자 조회 실패: $e');
    }
  }

  /// 조직별 환자 목록 조회
  Future<List<Patient>> getPatientsByOrganization(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('organization_id', isEqualTo: organizationId)
          .where('status', isEqualTo: 'ACTIVE')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('환자 목록 조회 실패: $e');
    }
  }

  /// 치료사별 환자 목록 조회
  Future<List<Patient>> getPatientsByTherapist(String therapistId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('assigned_therapist_id', isEqualTo: therapistId)
          .where('status', isEqualTo: 'ACTIVE')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('담당 환자 목록 조회 실패: $e');
    }
  }

  /// 보호자별 환자 목록 조회
  Future<List<Patient>> getPatientsByGuardian(String guardianId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('guardian_ids', arrayContains: guardianId)
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      return snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('보호자 환자 목록 조회 실패: $e');
    }
  }

  /// 환자 정보 업데이트
  Future<void> updatePatient(String patientId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(patientId).update(updates);
    } catch (e) {
      throw Exception('환자 정보 업데이트 실패: $e');
    }
  }

  /// 환자 상태 변경
  Future<void> updatePatientStatus(String patientId, String status) async {
    try {
      await _firestore.collection(_collection).doc(patientId).update({
        'status': status,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('환자 상태 변경 실패: $e');
    }
  }

  /// 환자 삭제 (소프트 삭제)
  Future<void> deletePatient(String patientId) async {
    try {
      await updatePatientStatus(patientId, 'INACTIVE');
    } catch (e) {
      throw Exception('환자 삭제 실패: $e');
    }
  }

  /// 환자 검색 (이름)
  Future<List<Patient>> searchPatientsByName(String organizationId, String name) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('organization_id', isEqualTo: organizationId)
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      // 클라이언트 사이드 필터링 (Firestore는 부분 문자열 검색 미지원)
      return snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .where((patient) => patient.name.contains(name))
          .toList();
    } catch (e) {
      throw Exception('환자 검색 실패: $e');
    }
  }

  /// Stream으로 환자 실시간 감시
  Stream<Patient?> watchPatient(String patientId) {
    return _firestore.collection(_collection).doc(patientId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Patient.fromFirestore(doc.data()!, doc.id);
    });
  }

  /// Stream으로 환자 목록 실시간 감시
  Stream<List<Patient>> watchPatientsByTherapist(String therapistId) {
    return _firestore
        .collection(_collection)
        .where('assigned_therapist_id', isEqualTo: therapistId)
        .where('status', isEqualTo: 'ACTIVE')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Patient.fromFirestore(doc.data(), doc.id)).toList();
    });
  }
}
