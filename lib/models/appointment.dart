import '../constants/enums.dart';

/// 예약 모델
class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String guardianId;
  final String therapistId;
  final String therapistName;
  final DateTime appointmentDate;
  final String timeSlot; // 예: "09:00-10:00"
  final AppointmentStatus status;
  final String? notes; // 요청 사항
  final String? therapistNotes; // 치료사 메모
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.guardianId,
    required this.therapistId,
    required this.therapistName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.notes,
    this.therapistNotes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 데이터로부터 객체 생성
  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      patientId: data['patient_id'] as String,
      patientName: data['patient_name'] as String,
      guardianId: data['guardian_id'] as String,
      therapistId: data['therapist_id'] as String,
      therapistName: data['therapist_name'] as String,
      appointmentDate: (data['appointment_date'] as dynamic).toDate(),
      timeSlot: data['time_slot'] as String,
      status: _parseStatus(data['status'] as String?),
      notes: data['notes'] as String?,
      therapistNotes: data['therapist_notes'] as String?,
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
      'guardian_id': guardianId,
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'appointment_date': appointmentDate,
      'time_slot': timeSlot,
      'status': _statusToString(status),
      'notes': notes,
      'therapist_notes': therapistNotes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'CONFIRMED':
        return AppointmentStatus.confirmed;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.pending;
    }
  }

  static String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.completed:
        return 'COMPLETED';
    }
  }

  /// 상태별 한글 텍스트
  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return '승인 대기';
      case AppointmentStatus.confirmed:
        return '예약 확정';
      case AppointmentStatus.cancelled:
        return '예약 취소';
      case AppointmentStatus.completed:
        return '치료 완료';
    }
  }

  /// 복사본 생성 (상태 변경 등에 사용)
  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? guardianId,
    String? therapistId,
    String? therapistName,
    DateTime? appointmentDate,
    String? timeSlot,
    AppointmentStatus? status,
    String? notes,
    String? therapistNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      guardianId: guardianId ?? this.guardianId,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      therapistNotes: therapistNotes ?? this.therapistNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
