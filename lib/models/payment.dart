import 'package:cloud_firestore/cloud_firestore.dart';

/// 결제 방식
enum PaymentMethod {
  cash,       // 현금
  card,       // 카드
  transfer,   // 계좌이체
  voucher,    // 횟수권
  other,      // 기타
}

/// 결제 모델
class Payment {
  final String id;
  final String patientId;          // 환자 ID
  final String patientName;        // 환자 이름
  final String organizationId;     // 조직 ID
  final String therapistId;        // 담당자 ID
  final String therapistName;      // 담당자 이름
  
  final String description;        // 결제 내용
  final double amount;             // 결제 금액
  final double discount;           // 할인 금액
  final double finalAmount;        // 최종 결제 금액
  
  final PaymentMethod paymentMethod;  // 결제 방식
  final bool useVoucher;           // 횟수권 사용 여부
  final int? voucherSessions;      // 차감된 횟수권 회차
  
  final String? memo;              // 결제 요약 메모
  final DateTime createdAt;        // 결제 일시
  
  Payment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.organizationId,
    required this.therapistId,
    required this.therapistName,
    required this.description,
    required this.amount,
    required this.discount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.useVoucher,
    this.voucherSessions,
    this.memo,
    required this.createdAt,
  });

  /// Firestore에서 데이터 로드
  factory Payment.fromFirestore(Map<String, dynamic> data, String id) {
    return Payment(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      patientName: data['patient_name'] as String? ?? '',
      organizationId: data['organization_id'] as String? ?? '',
      therapistId: data['therapist_id'] as String? ?? '',
      therapistName: data['therapist_name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (data['final_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: _parsePaymentMethod(data['payment_method'] as String?),
      useVoucher: data['use_voucher'] as bool? ?? false,
      voucherSessions: data['voucher_sessions'] as int?,
      memo: data['memo'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore에 저장할 데이터
  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'organization_id': organizationId,
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'description': description,
      'amount': amount,
      'discount': discount,
      'final_amount': finalAmount,
      'payment_method': paymentMethod.name,
      'use_voucher': useVoucher,
      'voucher_sessions': voucherSessions,
      'memo': memo,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// 문자열을 PaymentMethod로 변환
  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'voucher':
        return PaymentMethod.voucher;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash;
    }
  }

  /// 결제 방식 한글명
  String get paymentMethodName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return '현금';
      case PaymentMethod.card:
        return '카드';
      case PaymentMethod.transfer:
        return '계좌이체';
      case PaymentMethod.voucher:
        return '횟수권';
      case PaymentMethod.other:
        return '기타';
    }
  }

  /// 실제 결제 건인지 확인 (통계용)
  bool get isActualPayment {
    // 횟수권과 금액권 제외, 실제 결제 건만
    return paymentMethod == PaymentMethod.cash ||
           paymentMethod == PaymentMethod.card ||
           paymentMethod == PaymentMethod.transfer;
  }
}
