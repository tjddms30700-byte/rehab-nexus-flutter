import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assessment.dart';

/// 평가 데이터 서비스
class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'assessments';

  /// 평가 생성
  Future<String> createAssessment(Assessment assessment) async {
    try {
      final docRef = await _firestore.collection(_collection).add(assessment.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('평가 저장 실패: $e');
    }
  }

  /// 평가 조회 (ID)
  Future<Assessment?> getAssessment(String assessmentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(assessmentId).get();
      if (!doc.exists) return null;
      return Assessment.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('평가 조회 실패: $e');
    }
  }

  /// 환자별 평가 목록 조회
  Future<List<Assessment>> getAssessmentsByPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .orderBy('assessment_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Assessment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('평가 목록 조회 실패: $e');
    }
  }

  /// 최신 평가 조회
  Future<Assessment?> getLatestAssessment(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .orderBy('assessment_date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Assessment.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw Exception('최신 평가 조회 실패: $e');
    }
  }

  /// 기간별 평가 조회
  Future<List<Assessment>> getAssessmentsByDateRange(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .where('assessment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('assessment_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('assessment_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Assessment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('기간별 평가 조회 실패: $e');
    }
  }

  /// 평가 업데이트
  Future<void> updateAssessment(String assessmentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(assessmentId).update(updates);
    } catch (e) {
      throw Exception('평가 업데이트 실패: $e');
    }
  }

  /// 평가 삭제
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _firestore.collection(_collection).doc(assessmentId).delete();
    } catch (e) {
      throw Exception('평가 삭제 실패: $e');
    }
  }

  /// 평가 타입별 조회
  Future<List<Assessment>> getAssessmentsByType(String patientId, String assessmentType) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .where('assessment_type', isEqualTo: assessmentType)
          .orderBy('assessment_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Assessment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('평가 타입별 조회 실패: $e');
    }
  }

  /// Stream으로 평가 실시간 감시
  Stream<List<Assessment>> watchAssessmentsByPatient(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patient_id', isEqualTo: patientId)
        .orderBy('assessment_date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Assessment.fromFirestore(doc.data(), doc.id)).toList();
    });
  }
}
