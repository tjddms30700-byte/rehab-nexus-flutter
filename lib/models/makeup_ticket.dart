import '../constants/enums.dart';

/// 보강 티켓 모델
class MakeupTicket {
  final String id;
  final String patientId;
  final String patientName;
  final String originalAttendanceId; // 원래 결석/취소한 출석 ID
  final DateTime originalDate; // 원래 예정일
  final String originalTimeSlot; // 원래 시간대
  final MakeupTicketStatus status; // 사용 가능, 사용 완료, 만료
  final DateTime expiryDate; // 만료일
  final DateTime? usedDate; // 사용일
  final String? usedAttendanceId; // 사용된 출석 ID
  final String therapistId;
  final String therapistName;
  final String? notes; // 메모
  final DateTime createdAt;
  final DateTime? updatedAt;

  MakeupTicket({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.originalAttendanceId,
    required this.originalDate,
    required this.originalTimeSlot,
    required this.status,
    required this.expiryDate,
    this.usedDate,
    this.usedAttendanceId,
    required this.therapistId,
    required this.therapistName,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 데이터로부터 객체 생성
  factory MakeupTicket.fromFirestore(Map<String, dynamic> data, String id) {
    return MakeupTicket(
      id: id,
      patientId: data['patient_id'] as String,
      patientName: data['patient_name'] as String,
      originalAttendanceId: data['original_attendance_id'] as String,
      originalDate: (data['original_date'] as dynamic).toDate(),
      originalTimeSlot: data['original_time_slot'] as String,
      status: _parseStatus(data['status'] as String?),
      expiryDate: (data['expiry_date'] as dynamic).toDate(),
      usedDate: data['used_date'] != null
          ? (data['used_date'] as dynamic).toDate()
          : null,
      usedAttendanceId: data['used_attendance_id'] as String?,
      therapistId: data['therapist_id'] as String,
      therapistName: data['therapist_name'] as String,
      notes: data['notes'] as String?,
      createdAt: (data['created_at'] as dynamic).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as dynamic).toDate()
          : null,
    );
  }

  /// Firestore 저장용 데이터로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'original_attendance_id': originalAttendanceId,
      'original_date': originalDate,
      'original_time_slot': originalTimeSlot,
      'status': _statusToString(status),
      'expiry_date': expiryDate,
      'used_date': usedDate,
      'used_attendance_id': usedAttendanceId,
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static MakeupTicketStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':
        return MakeupTicketStatus.available;
      case 'USED':
        return MakeupTicketStatus.used;
      case 'EXPIRED':
        return MakeupTicketStatus.expired;
      default:
        return MakeupTicketStatus.available;
    }
  }

  static String _statusToString(MakeupTicketStatus status) {
    switch (status) {
      case MakeupTicketStatus.available:
        return 'AVAILABLE';
      case MakeupTicketStatus.used:
        return 'USED';
      case MakeupTicketStatus.expired:
        return 'EXPIRED';
    }
  }

  /// 상태별 한글 텍스트
  String get statusText {
    switch (status) {
      case MakeupTicketStatus.available:
        return '사용 가능';
      case MakeupTicketStatus.used:
        return '사용 완료';
      case MakeupTicketStatus.expired:
        return '만료';
    }
  }

  /// 보강권 사용 가능 여부
  bool get isAvailable {
    return status == MakeupTicketStatus.available &&
        DateTime.now().isBefore(expiryDate);
  }

  /// 복사본 생성
  MakeupTicket copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? originalAttendanceId,
    DateTime? originalDate,
    String? originalTimeSlot,
    MakeupTicketStatus? status,
    DateTime? expiryDate,
    DateTime? usedDate,
    String? usedAttendanceId,
    String? therapistId,
    String? therapistName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MakeupTicket(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      originalAttendanceId: originalAttendanceId ?? this.originalAttendanceId,
      originalDate: originalDate ?? this.originalDate,
      originalTimeSlot: originalTimeSlot ?? this.originalTimeSlot,
      status: status ?? this.status,
      expiryDate: expiryDate ?? this.expiryDate,
      usedDate: usedDate ?? this.usedDate,
      usedAttendanceId: usedAttendanceId ?? this.usedAttendanceId,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
