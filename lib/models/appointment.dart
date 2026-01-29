import '../constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 슬롯 상태 (4가지 고정)
enum SlotStatus {
  empty,      // 빈 슬롯 (회색)
  scheduled,  // 예약됨 (파랑)
  makeup,     // 보강 (초록)
  unprocessed // 미처리 (주황)
}

/// 예약 모델 (확장)
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
  
  // 추가: 출석 및 세션 상태
  final bool attended;              // 출석 여부
  final DateTime? attendedAt;       // 출석 처리 시각
  final bool sessionRecorded;       // 세션 기록 여부
  final DateTime? sessionRecordedAt; // 세션 기록 시각
  final String? sessionId;          // 세션 기록 ID
  final bool isMakeup;              // 보강권 사용 여부
  final String? makeupTicketId;     // 보강권 ID

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
    this.attended = false,
    this.attendedAt,
    this.sessionRecorded = false,
    this.sessionRecordedAt,
    this.sessionId,
    this.isMakeup = false,
    this.makeupTicketId,
  });

  /// 슬롯 상태 계산
  SlotStatus get slotStatus {
    if (status == AppointmentStatus.cancelled) {
      return SlotStatus.empty;
    }
    
    if (isMakeup) {
      return SlotStatus.makeup;
    }
    
    if (attended && !sessionRecorded) {
      return SlotStatus.unprocessed;
    }
    
    if (!attended && DateTime.now().isAfter(appointmentDate)) {
      return SlotStatus.unprocessed;
    }
    
    return SlotStatus.scheduled;
  }

  /// 슬롯 상태 색상
  Color get slotColor {
    switch (slotStatus) {
      case SlotStatus.empty:
        return const Color(0xFFEEEEEE); // 연회색
      case SlotStatus.scheduled:
        return const Color(0xFF2196F3); // 파랑
      case SlotStatus.makeup:
        return const Color(0xFF4CAF50); // 초록
      case SlotStatus.unprocessed:
        return const Color(0xFFFF9800); // 주황
    }
  }

  /// 슬롯 상태 텍스트
  String get slotStatusText {
    if (attended && !sessionRecorded) {
      return '출석완료';
    }
    if (!attended && DateTime.now().isAfter(appointmentDate)) {
      return '미처리';
    }
    if (isMakeup) {
      return '보강';
    }
    return '예약';
  }

  /// Firestore 데이터로부터 객체 생성
  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      patientName: data['patient_name'] as String? ?? '',
      guardianId: data['guardian_id'] as String? ?? '',
      therapistId: data['therapist_id'] as String? ?? '',
      therapistName: data['therapist_name'] as String? ?? '',
      appointmentDate: (data['appointment_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['time_slot'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      notes: data['notes'] as String?,
      therapistNotes: data['therapist_notes'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      attended: data['attended'] as bool? ?? false,
      attendedAt: data['attended_at'] != null
          ? (data['attended_at'] as Timestamp).toDate()
          : null,
      sessionRecorded: data['session_recorded'] as bool? ?? false,
      sessionRecordedAt: data['session_recorded_at'] != null
          ? (data['session_recorded_at'] as Timestamp).toDate()
          : null,
      sessionId: data['session_id'] as String?,
      isMakeup: data['is_makeup'] as bool? ?? false,
      makeupTicketId: data['makeup_ticket_id'] as String?,
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
      'appointment_date': Timestamp.fromDate(appointmentDate),
      'time_slot': timeSlot,
      'status': _statusToString(status),
      'notes': notes,
      'therapist_notes': therapistNotes,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'attended': attended,
      'attended_at': attendedAt != null ? Timestamp.fromDate(attendedAt!) : null,
      'session_recorded': sessionRecorded,
      'session_recorded_at': sessionRecordedAt != null ? Timestamp.fromDate(sessionRecordedAt!) : null,
      'session_id': sessionId,
      'is_makeup': isMakeup,
      'makeup_ticket_id': makeupTicketId,
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

  /// 복사 메서드 (상태 업데이트용)
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
    bool? attended,
    DateTime? attendedAt,
    bool? sessionRecorded,
    DateTime? sessionRecordedAt,
    String? sessionId,
    bool? isMakeup,
    String? makeupTicketId,
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
      attended: attended ?? this.attended,
      attendedAt: attendedAt ?? this.attendedAt,
      sessionRecorded: sessionRecorded ?? this.sessionRecorded,
      sessionRecordedAt: sessionRecordedAt ?? this.sessionRecordedAt,
      sessionId: sessionId ?? this.sessionId,
      isMakeup: isMakeup ?? this.isMakeup,
      makeupTicketId: makeupTicketId ?? this.makeupTicketId,
    );
  }
}
