// 보호자 정기 리포트 모델
// AQU LAB Care - AI 기반 맞춤형 수중재활 보호자 리포트

import 'package:cloud_firestore/cloud_firestore.dart';

/// 리포트 상태
enum ReportStatus {
  draft,      // 작성 중
  completed,  // 작성 완료
  sent,       // 발송됨
  read,       // 읽음
}

/// 보호자 정기 리포트 모델
class GuardianReport {
  final String id;
  final String patientId;          // 환자 ID
  final String patientName;        // 환자 이름
  final DateTime birthDate;        // 생년월일
  final String guardianId;         // 보호자 ID
  final String therapistId;        // 담당 치료사 ID
  final String therapistName;      // 담당 치료사 이름
  final String centerName;         // 센터명
  
  // 리포트 기간
  final DateTime periodStart;      // 리포트 시작일
  final DateTime periodEnd;        // 리포트 종료일
  
  // 0. 표지 정보
  final String reportTitle;        // 리포트 제목 (기본: "AI 기반 맞춤형 수중재활 보호자 리포트")
  final String footerNotice;       // 하단 고지 문구
  
  // 1. 치료 회기 요약
  final int totalSessions;         // 총 회기 수
  final int attendedSessions;      // 참석 회기 수
  final double attendanceRate;     // 출석률 (%)
  
  // 2. 주요 치료 목표
  final List<String> mainGoals;    // 주요 목표 리스트
  final String goalsProgress;      // 목표 달성 진척도 요약
  
  // 3. 치료 경과 및 발달 변화
  final String progressSummary;    // 전반적 경과 요약
  final List<DevelopmentChange> developmentChanges; // 발달 변화 항목들
  
  // 4. 주요 활동 및 개입 방법
  final List<TherapyActivity> mainActivities; // 주요 활동 리스트
  
  // 5. 측정 결과 및 평가
  final List<Assessment> assessments; // 평가 항목 리스트
  
  // 6. 종합 소견
  final String comprehensiveOpinion; // 치료사 종합 소견
  
  // 7. 가정 연계 활동 (홈 프로그램)
  final List<HomeProgram> homePrograms; // 가정 연계 활동 리스트
  
  // 8. 다음 치료 계획
  final String nextPlan;           // 다음 기간 치료 계획
  final List<String> nextGoals;    // 다음 기간 목표
  
  // 9. 보호자 전달 메시지
  final String messageToGuardian;  // 보호자 전달 메시지
  
  // 메타 정보
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? sentAt;
  final DateTime? readAt;
  final int version;               // 리포트 버전
  final List<ReportHistory> history; // 수정 이력
  
  GuardianReport({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.birthDate,
    required this.guardianId,
    required this.therapistId,
    required this.therapistName,
    required this.centerName,
    required this.periodStart,
    required this.periodEnd,
    this.reportTitle = "AI 기반 맞춤형 수중재활 보호자 리포트",
    this.footerNotice = "본 리포트는 아동의 재활 진행 상황을 보호자에게 안내하기 위한 문서입니다.",
    required this.totalSessions,
    required this.attendedSessions,
    required this.attendanceRate,
    required this.mainGoals,
    required this.goalsProgress,
    required this.progressSummary,
    required this.developmentChanges,
    required this.mainActivities,
    required this.assessments,
    required this.comprehensiveOpinion,
    required this.homePrograms,
    required this.nextPlan,
    required this.nextGoals,
    required this.messageToGuardian,
    this.status = ReportStatus.draft,
    required this.createdAt,
    this.completedAt,
    this.sentAt,
    this.readAt,
    this.version = 1,
    this.history = const [],
  });
  
  /// Firestore로부터 생성
  factory GuardianReport.fromFirestore(Map<String, dynamic> data, String documentId) {
    return GuardianReport(
      id: documentId,
      patientId: data['patient_id'] ?? '',
      patientName: data['patient_name'] ?? '',
      birthDate: (data['birth_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      guardianId: data['guardian_id'] ?? '',
      therapistId: data['therapist_id'] ?? '',
      therapistName: data['therapist_name'] ?? '',
      centerName: data['center_name'] ?? '',
      periodStart: (data['period_start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (data['period_end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportTitle: data['report_title'] ?? "AI 기반 맞춤형 수중재활 보호자 리포트",
      footerNotice: data['footer_notice'] ?? "본 리포트는 아동의 재활 진행 상황을 보호자에게 안내하기 위한 문서입니다.",
      totalSessions: data['total_sessions'] ?? 0,
      attendedSessions: data['attended_sessions'] ?? 0,
      attendanceRate: (data['attendance_rate'] ?? 0.0).toDouble(),
      mainGoals: List<String>.from(data['main_goals'] ?? []),
      goalsProgress: data['goals_progress'] ?? '',
      progressSummary: data['progress_summary'] ?? '',
      developmentChanges: (data['development_changes'] as List<dynamic>?)
          ?.map((e) => DevelopmentChange.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      mainActivities: (data['main_activities'] as List<dynamic>?)
          ?.map((e) => TherapyActivity.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      assessments: (data['assessments'] as List<dynamic>?)
          ?.map((e) => Assessment.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      comprehensiveOpinion: data['comprehensive_opinion'] ?? '',
      homePrograms: (data['home_programs'] as List<dynamic>?)
          ?.map((e) => HomeProgram.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      nextPlan: data['next_plan'] ?? '',
      nextGoals: List<String>.from(data['next_goals'] ?? []),
      messageToGuardian: data['message_to_guardian'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      sentAt: (data['sent_at'] as Timestamp?)?.toDate(),
      readAt: (data['read_at'] as Timestamp?)?.toDate(),
      version: data['version'] ?? 1,
      history: (data['history'] as List<dynamic>?)
          ?.map((e) => ReportHistory.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  /// Firestore로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'birth_date': Timestamp.fromDate(birthDate),
      'guardian_id': guardianId,
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'center_name': centerName,
      'period_start': Timestamp.fromDate(periodStart),
      'period_end': Timestamp.fromDate(periodEnd),
      'report_title': reportTitle,
      'footer_notice': footerNotice,
      'total_sessions': totalSessions,
      'attended_sessions': attendedSessions,
      'attendance_rate': attendanceRate,
      'main_goals': mainGoals,
      'goals_progress': goalsProgress,
      'progress_summary': progressSummary,
      'development_changes': developmentChanges.map((e) => e.toMap()).toList(),
      'main_activities': mainActivities.map((e) => e.toMap()).toList(),
      'assessments': assessments.map((e) => e.toMap()).toList(),
      'comprehensive_opinion': comprehensiveOpinion,
      'home_programs': homePrograms.map((e) => e.toMap()).toList(),
      'next_plan': nextPlan,
      'next_goals': nextGoals,
      'message_to_guardian': messageToGuardian,
      'status': _statusToString(status),
      'created_at': Timestamp.fromDate(createdAt),
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'sent_at': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'read_at': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'version': version,
      'history': history.map((e) => e.toMap()).toList(),
    };
  }
  
  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft':
        return ReportStatus.draft;
      case 'completed':
        return ReportStatus.completed;
      case 'sent':
        return ReportStatus.sent;
      case 'read':
        return ReportStatus.read;
      default:
        return ReportStatus.draft;
    }
  }
  
  static String _statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'draft';
      case ReportStatus.completed:
        return 'completed';
      case ReportStatus.sent:
        return 'sent';
      case ReportStatus.read:
        return 'read';
    }
  }
  
  /// 상태 텍스트
  String get statusText {
    switch (status) {
      case ReportStatus.draft:
        return '작성 중';
      case ReportStatus.completed:
        return '작성 완료';
      case ReportStatus.sent:
        return '발송됨';
      case ReportStatus.read:
        return '읽음';
    }
  }
}

/// 발달 변화 항목
class DevelopmentChange {
  final String category;      // 카테고리 (예: "신체 발달", "인지 발달", "사회성 발달")
  final String description;   // 변화 설명
  final String level;         // 수준 (예: "개선", "유지", "약화")
  
  DevelopmentChange({
    required this.category,
    required this.description,
    required this.level,
  });
  
  factory DevelopmentChange.fromMap(Map<String, dynamic> map) {
    return DevelopmentChange(
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      level: map['level'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'level': level,
    };
  }
}

/// 치료 활동
class TherapyActivity {
  final String activityName;  // 활동명
  final String purpose;       // 목적
  final String method;        // 방법
  final String result;        // 결과
  
  TherapyActivity({
    required this.activityName,
    required this.purpose,
    required this.method,
    required this.result,
  });
  
  factory TherapyActivity.fromMap(Map<String, dynamic> map) {
    return TherapyActivity(
      activityName: map['activity_name'] ?? '',
      purpose: map['purpose'] ?? '',
      method: map['method'] ?? '',
      result: map['result'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'activity_name': activityName,
      'purpose': purpose,
      'method': method,
      'result': result,
    };
  }
}

/// 평가 항목
class Assessment {
  final String assessmentName; // 평가명
  final String score;          // 점수/결과
  final String description;    // 설명
  final DateTime assessmentDate; // 평가일
  
  Assessment({
    required this.assessmentName,
    required this.score,
    required this.description,
    required this.assessmentDate,
  });
  
  factory Assessment.fromMap(Map<String, dynamic> map) {
    return Assessment(
      assessmentName: map['assessment_name'] ?? '',
      score: map['score'] ?? '',
      description: map['description'] ?? '',
      assessmentDate: (map['assessment_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'assessment_name': assessmentName,
      'score': score,
      'description': description,
      'assessment_date': Timestamp.fromDate(assessmentDate),
    };
  }
}

/// 홈 프로그램 (가정 연계 활동)
class HomeProgram {
  final String programName;    // 프로그램명
  final String description;    // 설명
  final String frequency;      // 빈도 (예: "주 3회, 각 10분")
  final String caution;        // 주의사항
  
  HomeProgram({
    required this.programName,
    required this.description,
    required this.frequency,
    required this.caution,
  });
  
  factory HomeProgram.fromMap(Map<String, dynamic> map) {
    return HomeProgram(
      programName: map['program_name'] ?? '',
      description: map['description'] ?? '',
      frequency: map['frequency'] ?? '',
      caution: map['caution'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'program_name': programName,
      'description': description,
      'frequency': frequency,
      'caution': caution,
    };
  }
}

/// 리포트 수정 이력
class ReportHistory {
  final DateTime modifiedAt;   // 수정 일시
  final String modifiedBy;     // 수정자 ID
  final String modifiedByName; // 수정자 이름
  final String changeDescription; // 변경 내용 설명
  final int version;           // 버전
  
  ReportHistory({
    required this.modifiedAt,
    required this.modifiedBy,
    required this.modifiedByName,
    required this.changeDescription,
    required this.version,
  });
  
  factory ReportHistory.fromMap(Map<String, dynamic> map) {
    return ReportHistory(
      modifiedAt: (map['modified_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modifiedBy: map['modified_by'] ?? '',
      modifiedByName: map['modified_by_name'] ?? '',
      changeDescription: map['change_description'] ?? '',
      version: map['version'] ?? 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'modified_at': Timestamp.fromDate(modifiedAt),
      'modified_by': modifiedBy,
      'modified_by_name': modifiedByName,
      'change_description': changeDescription,
      'version': version,
    };
  }
}
