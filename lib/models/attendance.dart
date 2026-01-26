import '../constants/enums.dart';

/// 출석 모델
class Attendance {
  final String id;
  final String patientId;
  final String patientName;
  final String sessionId; // 연결된 세션 ID
  final DateTime scheduleDate; // 예정 날짜
  final String timeSlot; // 예: "10:00-11:00"
  final AttendanceStatus status; // 출석, 결석, 취소, 보강
  final String? cancelReason; // 취소/결석 사유
  final bool hasMakeup; // 보강 여부
  final String? makeupId; // 보강 티켓 ID
  final String therapistId;
  final String therapistName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.sessionId,
    required this.scheduleDate,
    required this.timeSlot,
    required this.status,
    this.cancelReason,
    this.hasMakeup = false,
    this.makeupId,
    required this.therapistId,
    required this.therapistName,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 데이터로부터 객체 생성
  factory Attendance.fromFirestore(Map<String, dynamic> data, String id) {
    return Attendance(
      id: id,
      patientId: data['patient_id'] as String,
      patientName: data['patient_name'] as String,
      sessionId: data['session_id'] as String,
      scheduleDate: (data['schedule_date'] as dynamic).toDate(),
      timeSlot: data['time_slot'] as String,
      status: _parseStatus(data['status'] as String?),
      cancelReason: data['cancel_reason'] as String?,
      hasMakeup: data['has_makeup'] as bool? ?? false,
      makeupId: data['makeup_id'] as String?,
      therapistId: data['therapist_id'] as String,
      therapistName: data['therapist_name'] as String,
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
      'session_id': sessionId,
      'schedule_date': scheduleDate,
      'time_slot': timeSlot,
      'status': _statusToString(status),
      'cancel_reason': cancelReason,
      'has_makeup': hasMakeup,
      'makeup_id': makeupId,
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static AttendanceStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'CANCELLED':
        return AttendanceStatus.cancelled;
      case 'MAKEUP':
        return AttendanceStatus.makeup;
      default:
        return AttendanceStatus.present;
    }
  }

  static String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.cancelled:
        return 'CANCELLED';
      case AttendanceStatus.makeup:
        return 'MAKEUP';
    }
  }

  /// 상태별 한글 텍스트
  String get statusText {
    switch (status) {
      case AttendanceStatus.present:
        return '출석';
      case AttendanceStatus.absent:
        return '결석';
      case AttendanceStatus.cancelled:
        return '취소';
      case AttendanceStatus.makeup:
        return '보강';
    }
  }

  /// 복사본 생성
  Attendance copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? sessionId,
    DateTime? scheduleDate,
    String? timeSlot,
    AttendanceStatus? status,
    String? cancelReason,
    bool? hasMakeup,
    String? makeupId,
    String? therapistId,
    String? therapistName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      sessionId: sessionId ?? this.sessionId,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      hasMakeup: hasMakeup ?? this.hasMakeup,
      makeupId: makeupId ?? this.makeupId,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
