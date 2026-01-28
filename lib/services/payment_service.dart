import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

/// 결제 서비스
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 결제 등록
  Future<void> addPayment(Payment payment) async {
    try {
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .set(payment.toFirestore());
    } catch (e) {
      throw Exception('결제 등록 실패: $e');
    }
  }

  /// 환자별 결제 내역 조회
  Future<List<Payment>> getPaymentsByPatient(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('patient_id', isEqualTo: patientId)
          .get();

      final payments = querySnapshot.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 정렬 (최신순)
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return payments;
    } catch (e) {
      throw Exception('결제 내역 조회 실패: $e');
    }
  }

  /// 조직별 결제 내역 조회
  Future<List<Payment>> getPaymentsByOrganization(String organizationId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      final payments = querySnapshot.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 정렬 (최신순)
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return payments;
    } catch (e) {
      throw Exception('결제 내역 조회 실패: $e');
    }
  }

  /// 기간별 결제 내역 조회
  Future<List<Payment>> getPaymentsByDateRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      final payments = querySnapshot.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 날짜 필터링 및 정렬
      final filteredPayments = payments.where((payment) {
        return payment.createdAt.isAfter(startDate) &&
               payment.createdAt.isBefore(endDate);
      }).toList();

      filteredPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredPayments;
    } catch (e) {
      throw Exception('결제 내역 조회 실패: $e');
    }
  }

  /// 실제 결제 건만 조회 (통계용)
  Future<List<Payment>> getActualPayments(String organizationId) async {
    try {
      final allPayments = await getPaymentsByOrganization(organizationId);
      
      // 실제 결제 건만 필터링
      return allPayments.where((payment) => payment.isActualPayment).toList();
    } catch (e) {
      throw Exception('결제 통계 조회 실패: $e');
    }
  }

  /// 결제 삭제
  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
    } catch (e) {
      throw Exception('결제 삭제 실패: $e');
    }
  }

  /// 결제 수정
  Future<void> updatePayment(Payment payment) async {
    try {
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update(payment.toFirestore());
    } catch (e) {
      throw Exception('결제 수정 실패: $e');
    }
  }
}
