/// 환자 상태
enum PatientStatus {
  active,
  inactive,
  discharged,
}

/// 평가 유형
enum AssessmentType {
  initial,
  reassessment,
  discharge,
}

/// 평가 항목 점수 타입
enum ScoringType {
  scale1To5,
  binary,
  numeric,
  text,
}

/// 평가 카테고리
enum AssessmentCategory {
  functional,
  sensory,
  buoyancy,
  rom,
}

/// 목표 상태
enum GoalStatus {
  inProgress,
  achieved,
  revised,
  cancelled,
}

/// 목표 우선순위
enum GoalPriority {
  high,
  medium,
  low,
}

/// 목표 카테고리
enum GoalCategory {
  functional,
  social,
  cognitive,
  physical,
}

/// 콘텐츠 유형
enum ContentType {
  aquatic,
  general,
  ot,
  pt,
}

/// 난이도 레벨
enum DifficultyLevel {
  level1,
  level2,
  level3,
  level4,
  level5,
}

/// 중재 계획 상태
enum InterventionStatus {
  active,
  completed,
  paused,
}

/// 활동 강도
enum ActivityIntensity {
  low,
  medium,
  high,
}

/// 환자 반응
enum PatientResponse {
  positive,
  neutral,
  negative,
}

/// 협조도
enum CooperationLevel {
  excellent,
  good,
  fair,
  poor,
}

/// 피로도
enum FatigueLevel {
  low,
  medium,
  high,
}

/// 리포트 유형
enum ReportType {
  weekly,
  monthly,
  custom,
}

/// 리포트 상태
enum ReportStatus {
  draft,
  sent,
  viewed,
}

/// 홈프로그램 상태
enum HomeProgramStatus {
  active,
  completed,
}

/// 홈프로그램 난이도
enum HomeProgramDifficulty {
  easy,
  moderate,
  hard,
}

/// 성과 지표 유형
enum MetricType {
  rom,
  balance,
  coordination,
  buoyancy,
  sensory,
}

/// 센터 유형
enum OrganizationType {
  rehabCenter,
  hospital,
  nursingHome,
}

/// 예약 상태
enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

/// 문의 상태
enum InquiryStatus {
  pending,
  answered,
  closed,
}

/// 출석 상태
enum AttendanceStatus {
  present, // 출석
  absent, // 결석
  cancelled, // 취소
  makeup, // 보강
}

/// 보강 티켓 상태
enum MakeupTicketStatus {
  available, // 사용 가능
  used, // 사용 완료
  expired, // 만료
}

/// 공지사항 유형
enum NoticeType {
  center, // 센터 공지
  customer, // 고객 공지
}

/// 공지사항 우선순위
enum NoticePriority {
  normal, // 일반
  important, // 중요
  urgent, // 긴급
}

extension PatientStatusExtension on PatientStatus {
  String get value {
    switch (this) {
      case PatientStatus.active:
        return 'ACTIVE';
      case PatientStatus.inactive:
        return 'INACTIVE';
      case PatientStatus.discharged:
        return 'DISCHARGED';
    }
  }

  String get displayName {
    switch (this) {
      case PatientStatus.active:
        return '활성';
      case PatientStatus.inactive:
        return '비활성';
      case PatientStatus.discharged:
        return '퇴원';
    }
  }
}

// 나머지 enum들도 필요시 extension 추가
