import 'package:cloud_firestore/cloud_firestore.dart';

/// 초대 상태
enum InviteStatus {
  invited,   // 초대됨 (미사용)
  accepted,  // 사용됨
  expired,   // 만료됨
  cancelled  // 취소됨
}

/// 초대 모델
class Invite {
  final String id;
  final String codeHash;           // SHA256 해시된 코드 (보안)
  final String email;              // 초대 대상 이메일
  final String role;               // therapist | guardian
  final String centerId;           // 센터 ID
  final String? centerName;        // 센터 이름 (denormalized)
  final String? patientId;         // guardian용 연결 환자
  final String? patientName;       // 환자 이름 (denormalized)
  final DateTime expiresAt;        // 만료 시각
  final DateTime? usedAt;          // 사용 시각
  final String? usedByUid;         // 사용한 사용자 UID
  final InviteStatus status;       // 상태
  final DateTime createdAt;        // 생성 시각
  final String createdByUid;       // 생성한 관리자 UID
  final String? createdByName;     // 생성한 관리자 이름
  
  Invite({
    required this.id,
    required this.codeHash,
    required this.email,
    required this.role,
    required this.centerId,
    this.centerName,
    this.patientId,
    this.patientName,
    required this.expiresAt,
    this.usedAt,
    this.usedByUid,
    required this.status,
    required this.createdAt,
    required this.createdByUid,
    this.createdByName,
  });

  /// Firestore에서 로드
  factory Invite.fromFirestore(Map<String, dynamic> data, String id) {
    return Invite(
      id: id,
      codeHash: data['code_hash'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'therapist',
      centerId: data['center_id'] as String? ?? '',
      centerName: data['center_name'] as String?,
      patientId: data['patient_id'] as String?,
      patientName: data['patient_name'] as String?,
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usedAt: data['used_at'] != null
          ? (data['used_at'] as Timestamp).toDate()
          : null,
      usedByUid: data['used_by_uid'] as String?,
      status: _parseStatus(data['status'] as String?),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByUid: data['created_by_uid'] as String? ?? '',
      createdByName: data['created_by_name'] as String?,
    );
  }

  /// Firestore에 저장
  Map<String, dynamic> toFirestore() {
    return {
      'code_hash': codeHash,
      'email': email,
      'role': role,
      'center_id': centerId,
      'center_name': centerName,
      'patient_id': patientId,
      'patient_name': patientName,
      'expires_at': Timestamp.fromDate(expiresAt),
      'used_at': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'used_by_uid': usedByUid,
      'status': _statusToString(status),
      'created_at': Timestamp.fromDate(createdAt),
      'created_by_uid': createdByUid,
      'created_by_name': createdByName,
    };
  }

  /// 만료 여부 확인
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt) && status == InviteStatus.invited;
  }

  /// 사용 가능 여부
  bool get isUsable {
    return status == InviteStatus.invited && !isExpired;
  }

  /// 역할 한글명
  String get roleDisplayName {
    switch (role) {
      case 'therapist':
        return '치료사';
      case 'guardian':
        return '보호자';
      case 'admin':
        return '센터장';
      default:
        return role;
    }
  }

  /// 상태 한글명
  String get statusDisplayName {
    switch (status) {
      case InviteStatus.invited:
        return isExpired ? '만료' : '대기';
      case InviteStatus.accepted:
        return '사용완료';
      case InviteStatus.expired:
        return '만료';
      case InviteStatus.cancelled:
        return '취소';
    }
  }

  static InviteStatus _parseStatus(String? status) {
    switch (status) {
      case 'invited':
        return InviteStatus.invited;
      case 'accepted':
        return InviteStatus.accepted;
      case 'expired':
        return InviteStatus.expired;
      case 'cancelled':
        return InviteStatus.cancelled;
      default:
        return InviteStatus.invited;
    }
  }

  static String _statusToString(InviteStatus status) {
    switch (status) {
      case InviteStatus.invited:
        return 'invited';
      case InviteStatus.accepted:
        return 'accepted';
      case InviteStatus.expired:
        return 'expired';
      case InviteStatus.cancelled:
        return 'cancelled';
    }
  }

  /// 복사 메서드
  Invite copyWith({
    String? id,
    String? codeHash,
    String? email,
    String? role,
    String? centerId,
    String? centerName,
    String? patientId,
    String? patientName,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedByUid,
    InviteStatus? status,
    DateTime? createdAt,
    String? createdByUid,
    String? createdByName,
  }) {
    return Invite(
      id: id ?? this.id,
      codeHash: codeHash ?? this.codeHash,
      email: email ?? this.email,
      role: role ?? this.role,
      centerId: centerId ?? this.centerId,
      centerName: centerName ?? this.centerName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedByUid: usedByUid ?? this.usedByUid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
