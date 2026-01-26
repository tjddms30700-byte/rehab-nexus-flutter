import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inquiry.dart';
import '../constants/enums.dart';

/// 문의 서비스
class InquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'inquiries';

  /// 문의 생성
  Future<String> createInquiry(Inquiry inquiry) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(inquiry.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('문의 생성 실패: $e');
    }
  }

  /// 보호자의 문의 목록 조회
  Future<List<Inquiry>> getInquiriesByGuardian(String guardianId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('guardian_id', isEqualTo: guardianId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Inquiry.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('문의 목록 조회 실패: $e');
    }
  }

  /// 치료사의 문의 목록 조회
  Future<List<Inquiry>> getInquiriesByTherapist(String therapistId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('therapist_id', isEqualTo: therapistId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Inquiry.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('문의 목록 조회 실패: $e');
    }
  }

  /// 문의에 답변 작성
  Future<void> answerInquiry(String inquiryId, String answer) async {
    try {
      await _firestore.collection(_collectionName).doc(inquiryId).update({
        'answer': answer,
        'answered_at': FieldValue.serverTimestamp(),
        'status': 'ANSWERED',
      });
    } catch (e) {
      throw Exception('답변 작성 실패: $e');
    }
  }

  /// 문의 상태 변경
  Future<void> updateInquiryStatus(
      String inquiryId, InquiryStatus status) async {
    try {
      await _firestore.collection(_collectionName).doc(inquiryId).update({
        'status': _statusToString(status),
      });
    } catch (e) {
      throw Exception('문의 상태 변경 실패: $e');
    }
  }

  String _statusToString(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.pending:
        return 'PENDING';
      case InquiryStatus.answered:
        return 'ANSWERED';
      case InquiryStatus.closed:
        return 'CLOSED';
    }
  }
}
