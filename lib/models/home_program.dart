import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

/// 홈프로그램 활동
class HomeActivity {
  final String activityId;
  final String title;
  final String description;
  final String frequency; // 예: "매일 2회"
  final String duration; // 예: "15분"
  final List<String> instructions; // 수행 방법 (단계별)
  final List<String> precautions; // 주의사항
  final String? mediaUrl; // 참고 영상/이미지 URL

  HomeActivity({
    required this.activityId,
    required this.title,
    required this.description,
    required this.frequency,
    required this.duration,
    required this.instructions,
    this.precautions = const [],
    this.mediaUrl,
  });

  factory HomeActivity.fromMap(Map<String, dynamic> data) {
    return HomeActivity(
      activityId: data['activity_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      frequency: data['frequency'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      instructions: List<String>.from(data['instructions'] as List? ?? []),
      precautions: List<String>.from(data['precautions'] as List? ?? []),
      mediaUrl: data['media_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activity_id': activityId,
      'title': title,
      'description': description,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'precautions': precautions,
      if (mediaUrl != null) 'media_url': mediaUrl,
    };
  }
}

/// 홈프로그램 (가정 연계 프로그램)
class HomeProgram {
  final String id;
  final String patientId;
  final String month; // YYYY-MM 형식
  final List<String> goals; // 이번 달 목표
  final List<HomeActivity> activities; // 활동 리스트
  final HomeProgramStatus status;
  final DateTime createdAt;

  HomeProgram({
    required this.id,
    required this.patientId,
    required this.month,
    this.goals = const [],
    required this.activities,
    this.status = HomeProgramStatus.active,
    required this.createdAt,
  });

  factory HomeProgram.fromFirestore(Map<String, dynamic> data, String id) {
    return HomeProgram(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      month: data['month'] as String? ?? '',
      goals: List<String>.from(data['goals'] as List? ?? []),
      activities: (data['activities'] as List?)
              ?.map((a) => HomeActivity.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(data['status'] as String?),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'month': month,
      'goals': goals,
      'activities': activities.map((a) => a.toMap()).toList(),
      'status': _statusToString(status),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static HomeProgramStatus _parseStatus(String? status) {
    switch (status) {
      case 'ACTIVE':
        return HomeProgramStatus.active;
      case 'COMPLETED':
        return HomeProgramStatus.completed;
      default:
        return HomeProgramStatus.active;
    }
  }

  static String _statusToString(HomeProgramStatus status) {
    switch (status) {
      case HomeProgramStatus.active:
        return 'ACTIVE';
      case HomeProgramStatus.completed:
        return 'COMPLETED';
    }
  }
}

/// 홈프로그램 피드백 (보호자 수행 기록)
class HomeProgramFeedback {
  final String id;
  final String homeProgramId;
  final String activityId;
  final String guardianId;
  final DateTime completionDate;
  final bool completed; // 수행 여부
  final HomeProgramDifficulty? difficulty; // 난이도 평가
  final String? notes; // 보호자 코멘트
  final String? videoUrl; // 업로드된 영상 URL (선택)
  final DateTime createdAt;

  HomeProgramFeedback({
    required this.id,
    required this.homeProgramId,
    required this.activityId,
    required this.guardianId,
    required this.completionDate,
    required this.completed,
    this.difficulty,
    this.notes,
    this.videoUrl,
    required this.createdAt,
  });

  factory HomeProgramFeedback.fromFirestore(
      Map<String, dynamic> data, String id) {
    return HomeProgramFeedback(
      id: id,
      homeProgramId: data['home_program_id'] as String? ?? '',
      activityId: data['activity_id'] as String? ?? '',
      guardianId: data['guardian_id'] as String? ?? '',
      completionDate:
          (data['completion_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: data['completed'] as bool? ?? false,
      difficulty: _parseDifficulty(data['difficulty'] as String?),
      notes: data['notes'] as String?,
      videoUrl: data['video_url'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'home_program_id': homeProgramId,
      'activity_id': activityId,
      'guardian_id': guardianId,
      'completion_date': Timestamp.fromDate(completionDate),
      'completed': completed,
      if (difficulty != null) 'difficulty': _difficultyToString(difficulty!),
      if (notes != null) 'notes': notes,
      if (videoUrl != null) 'video_url': videoUrl,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static HomeProgramDifficulty? _parseDifficulty(String? difficulty) {
    if (difficulty == null) return null;
    switch (difficulty) {
      case 'EASY':
        return HomeProgramDifficulty.easy;
      case 'MODERATE':
        return HomeProgramDifficulty.moderate;
      case 'HARD':
        return HomeProgramDifficulty.hard;
      default:
        return null;
    }
  }

  static String _difficultyToString(HomeProgramDifficulty difficulty) {
    switch (difficulty) {
      case HomeProgramDifficulty.easy:
        return 'EASY';
      case HomeProgramDifficulty.moderate:
        return 'MODERATE';
      case HomeProgramDifficulty.hard:
        return 'HARD';
    }
  }
}

/// 리포트 데이터 (PDF 생성용)
class ReportData {
  final Map<String, dynamic> goalsSummary; // 목표 요약
  final Map<String, dynamic> sessionSummary; // 세션 요약
  final List<ProgressMetric> progressMetrics; // 성과 지표
  final String therapistComments; // 치료사 코멘트
  final String nextSteps; // 다음 계획

  ReportData({
    required this.goalsSummary,
    required this.sessionSummary,
    required this.progressMetrics,
    required this.therapistComments,
    required this.nextSteps,
  });

  factory ReportData.fromMap(Map<String, dynamic> data) {
    return ReportData(
      goalsSummary: data['goals_summary'] as Map<String, dynamic>? ?? {},
      sessionSummary: data['session_summary'] as Map<String, dynamic>? ?? {},
      progressMetrics: (data['progress_metrics'] as List?)
              ?.map((m) => ProgressMetric.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      therapistComments: data['therapist_comments'] as String? ?? '',
      nextSteps: data['next_steps'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goals_summary': goalsSummary,
      'session_summary': sessionSummary,
      'progress_metrics': progressMetrics.map((m) => m.toMap()).toList(),
      'therapist_comments': therapistComments,
      'next_steps': nextSteps,
    };
  }
}

/// 성과 지표 (차트용)
class ProgressMetric {
  final String label; // 지표 이름
  final double value; // 값
  final String unit; // 단위
  final DateTime date; // 측정 날짜

  ProgressMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.date,
  });

  factory ProgressMetric.fromMap(Map<String, dynamic> data) {
    return ProgressMetric(
      label: data['label'] as String? ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      'unit': unit,
      'date': Timestamp.fromDate(date),
    };
  }
}

/// 리포트
class Report {
  final String id;
  final String patientId;
  final ReportType reportType; // 주간/월간/커스텀
  final DateTime periodStart; // 기간 시작
  final DateTime periodEnd; // 기간 종료
  final String generatedBy; // 생성자 (치료사 ID)
  final ReportData data; // 리포트 데이터
  final String? pdfUrl; // PDF URL
  final ReportStatus status; // 상태
  final DateTime? sentAt; // 발송 시간
  final DateTime createdAt;

  Report({
    required this.id,
    required this.patientId,
    required this.reportType,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedBy,
    required this.data,
    this.pdfUrl,
    this.status = ReportStatus.draft,
    this.sentAt,
    required this.createdAt,
  });

  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      reportType: _parseReportType(data['report_type'] as String?),
      periodStart:
          (data['period_start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd:
          (data['period_end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      generatedBy: data['generated_by'] as String? ?? '',
      data: ReportData.fromMap(data['data'] as Map<String, dynamic>? ?? {}),
      pdfUrl: data['pdf_url'] as String?,
      status: _parseStatus(data['status'] as String?),
      sentAt: (data['sent_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'report_type': _reportTypeToString(reportType),
      'period_start': Timestamp.fromDate(periodStart),
      'period_end': Timestamp.fromDate(periodEnd),
      'generated_by': generatedBy,
      'data': data.toMap(),
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      'status': _statusToString(status),
      if (sentAt != null) 'sent_at': Timestamp.fromDate(sentAt!),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static ReportType _parseReportType(String? type) {
    switch (type) {
      case 'WEEKLY':
        return ReportType.weekly;
      case 'MONTHLY':
        return ReportType.monthly;
      case 'CUSTOM':
        return ReportType.custom;
      default:
        return ReportType.monthly;
    }
  }

  static String _reportTypeToString(ReportType type) {
    switch (type) {
      case ReportType.weekly:
        return 'WEEKLY';
      case ReportType.monthly:
        return 'MONTHLY';
      case ReportType.custom:
        return 'CUSTOM';
    }
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'DRAFT':
        return ReportStatus.draft;
      case 'SENT':
        return ReportStatus.sent;
      case 'VIEWED':
        return ReportStatus.viewed;
      default:
        return ReportStatus.draft;
    }
  }

  static String _statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'DRAFT';
      case ReportStatus.sent:
        return 'SENT';
      case ReportStatus.viewed:
        return 'VIEWED';
    }
  }
}
