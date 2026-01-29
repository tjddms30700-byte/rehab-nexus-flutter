import 'package:cloud_firestore/cloud_firestore.dart';

/// 환자 통계 (캐시)
/// 빠른 조회를 위한 집계 데이터
class PatientStats {
  final String patientId;
  final int totalVisits;              // 총 방문 횟수
  final DateTime? lastVisitAt;        // 마지막 방문 시각
  final String? activeVoucherId;      // 활성 이용권 ID
  final String? activeVoucherName;    // 활성 이용권 이름
  final int? remainingCount;          // 남은 횟수
  final String? primaryTherapistUid;  // 담당 치료사 UID
  final String? primaryTherapistName; // 담당 치료사 이름
  final DateTime updatedAt;           // 마지막 갱신 시각

  PatientStats({
    required this.patientId,
    required this.totalVisits,
    this.lastVisitAt,
    this.activeVoucherId,
    this.activeVoucherName,
    this.remainingCount,
    this.primaryTherapistUid,
    this.primaryTherapistName,
    required this.updatedAt,
  });

  /// Firestore에서 로드
  factory PatientStats.fromFirestore(Map<String, dynamic> data, String id) {
    return PatientStats(
      patientId: id,
      totalVisits: data['total_visits'] as int? ?? 0,
      lastVisitAt: data['last_visit_at'] != null
          ? (data['last_visit_at'] as Timestamp).toDate()
          : null,
      activeVoucherId: data['active_voucher_id'] as String?,
      activeVoucherName: data['active_voucher_name'] as String?,
      remainingCount: data['remaining_count'] as int?,
      primaryTherapistUid: data['primary_therapist_uid'] as String?,
      primaryTherapistName: data['primary_therapist_name'] as String?,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore에 저장
  Map<String, dynamic> toFirestore() {
    return {
      'total_visits': totalVisits,
      'last_visit_at': lastVisitAt != null ? Timestamp.fromDate(lastVisitAt!) : null,
      'active_voucher_id': activeVoucherId,
      'active_voucher_name': activeVoucherName,
      'remaining_count': remainingCount,
      'primary_therapist_uid': primaryTherapistUid,
      'primary_therapist_name': primaryTherapistName,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// 복사 메서드
  PatientStats copyWith({
    String? patientId,
    int? totalVisits,
    DateTime? lastVisitAt,
    String? activeVoucherId,
    String? activeVoucherName,
    int? remainingCount,
    String? primaryTherapistUid,
    String? primaryTherapistName,
    DateTime? updatedAt,
  }) {
    return PatientStats(
      patientId: patientId ?? this.patientId,
      totalVisits: totalVisits ?? this.totalVisits,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      activeVoucherId: activeVoucherId ?? this.activeVoucherId,
      activeVoucherName: activeVoucherName ?? this.activeVoucherName,
      remainingCount: remainingCount ?? this.remainingCount,
      primaryTherapistUid: primaryTherapistUid ?? this.primaryTherapistUid,
      primaryTherapistName: primaryTherapistName ?? this.primaryTherapistName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 초기 통계 생성
  static PatientStats initial(String patientId) {
    return PatientStats(
      patientId: patientId,
      totalVisits: 0,
      updatedAt: DateTime.now(),
    );
  }
}
