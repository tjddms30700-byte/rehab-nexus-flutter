import '../constants/enums.dart';

/// 문의 모델
class Inquiry {
  final String id;
  final String patientId;
  final String patientName;
  final String guardianId;
  final String guardianName;
  final String therapistId;
  final String title;
  final String content;
  final InquiryStatus status;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;

  Inquiry({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.guardianId,
    required this.guardianName,
    required this.therapistId,
    required this.title,
    required this.content,
    required this.status,
    this.answer,
    this.answeredAt,
    required this.createdAt,
  });

  factory Inquiry.fromFirestore(Map<String, dynamic> data, String id) {
    return Inquiry(
      id: id,
      patientId: data['patient_id'] as String,
      patientName: data['patient_name'] as String,
      guardianId: data['guardian_id'] as String,
      guardianName: data['guardian_name'] as String,
      therapistId: data['therapist_id'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      status: _parseStatus(data['status'] as String?),
      answer: data['answer'] as String?,
      answeredAt: data['answered_at'] != null
          ? (data['answered_at'] as dynamic).toDate()
          : null,
      createdAt: (data['created_at'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'guardian_id': guardianId,
      'guardian_name': guardianName,
      'therapist_id': therapistId,
      'title': title,
      'content': content,
      'status': _statusToString(status),
      'answer': answer,
      'answered_at': answeredAt,
      'created_at': createdAt,
    };
  }

  static InquiryStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return InquiryStatus.pending;
      case 'ANSWERED':
        return InquiryStatus.answered;
      case 'CLOSED':
        return InquiryStatus.closed;
      default:
        return InquiryStatus.pending;
    }
  }

  static String _statusToString(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.pending:
        return 'PENDING';
      case InquiryStatus.answered:
        return 'ANSWERED';
      case InquiryStatus.closed:
        return 'CLOSED';
    }
  }

  String get statusText {
    switch (status) {
      case InquiryStatus.pending:
        return '답변 대기';
      case InquiryStatus.answered:
        return '답변 완료';
      case InquiryStatus.closed:
        return '종료';
    }
  }
}
