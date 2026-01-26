import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

/// 활동 기록
class ActivityRecord {
  final String contentId; // 콘텐츠 ID
  final String contentTitle; // 콘텐츠 제목 (캐싱용)
  final int durationMinutes; // 활동 시간 (분)
  final ActivityIntensity intensity; // 강도
  final PatientResponse patientResponse; // 환자 반응
  final String? notes; // 비고

  ActivityRecord({
    required this.contentId,
    required this.contentTitle,
    required this.durationMinutes,
    required this.intensity,
    required this.patientResponse,
    this.notes,
  });

  factory ActivityRecord.fromMap(Map<String, dynamic> data) {
    return ActivityRecord(
      contentId: data['content_id'] as String? ?? '',
      contentTitle: data['content_title'] as String? ?? '',
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 0,
      intensity: _parseIntensity(data['intensity'] as String?),
      patientResponse: _parseResponse(data['patient_response'] as String?),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content_id': contentId,
      'content_title': contentTitle,
      'duration_minutes': durationMinutes,
      'intensity': _intensityToString(intensity),
      'patient_response': _responseToString(patientResponse),
      if (notes != null) 'notes': notes,
    };
  }

  static ActivityIntensity _parseIntensity(String? intensity) {
    switch (intensity) {
      case 'LOW':
        return ActivityIntensity.low;
      case 'MEDIUM':
        return ActivityIntensity.medium;
      case 'HIGH':
        return ActivityIntensity.high;
      default:
        return ActivityIntensity.medium;
    }
  }

  static String _intensityToString(ActivityIntensity intensity) {
    switch (intensity) {
      case ActivityIntensity.low:
        return 'LOW';
      case ActivityIntensity.medium:
        return 'MEDIUM';
      case ActivityIntensity.high:
        return 'HIGH';
    }
  }

  static PatientResponse _parseResponse(String? response) {
    switch (response) {
      case 'POSITIVE':
        return PatientResponse.positive;
      case 'NEUTRAL':
        return PatientResponse.neutral;
      case 'NEGATIVE':
        return PatientResponse.negative;
      default:
        return PatientResponse.neutral;
    }
  }

  static String _responseToString(PatientResponse response) {
    switch (response) {
      case PatientResponse.positive:
        return 'POSITIVE';
      case PatientResponse.neutral:
        return 'NEUTRAL';
      case PatientResponse.negative:
        return 'NEGATIVE';
    }
  }
}

/// 세션 관찰 소견
class SessionObservations {
  final String mood; // 기분 상태
  final CooperationLevel cooperation; // 협조도
  final FatigueLevel fatigueLevel; // 피로도
  final String? specialNotes; // 특이사항

  SessionObservations({
    required this.mood,
    required this.cooperation,
    required this.fatigueLevel,
    this.specialNotes,
  });

  factory SessionObservations.fromMap(Map<String, dynamic> data) {
    return SessionObservations(
      mood: data['mood'] as String? ?? '',
      cooperation: _parseCooperation(data['cooperation'] as String?),
      fatigueLevel: _parseFatigue(data['fatigue_level'] as String?),
      specialNotes: data['special_notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'cooperation': _cooperationToString(cooperation),
      'fatigue_level': _fatigueToString(fatigueLevel),
      if (specialNotes != null) 'special_notes': specialNotes,
    };
  }

  static CooperationLevel _parseCooperation(String? cooperation) {
    switch (cooperation) {
      case 'EXCELLENT':
        return CooperationLevel.excellent;
      case 'GOOD':
        return CooperationLevel.good;
      case 'FAIR':
        return CooperationLevel.fair;
      case 'POOR':
        return CooperationLevel.poor;
      default:
        return CooperationLevel.good;
    }
  }

  static String _cooperationToString(CooperationLevel cooperation) {
    switch (cooperation) {
      case CooperationLevel.excellent:
        return 'EXCELLENT';
      case CooperationLevel.good:
        return 'GOOD';
      case CooperationLevel.fair:
        return 'FAIR';
      case CooperationLevel.poor:
        return 'POOR';
    }
  }

  static FatigueLevel _parseFatigue(String? fatigue) {
    switch (fatigue) {
      case 'LOW':
        return FatigueLevel.low;
      case 'MEDIUM':
        return FatigueLevel.medium;
      case 'HIGH':
        return FatigueLevel.high;
      default:
        return FatigueLevel.medium;
    }
  }

  static String _fatigueToString(FatigueLevel fatigue) {
    switch (fatigue) {
      case FatigueLevel.low:
        return 'LOW';
      case FatigueLevel.medium:
        return 'MEDIUM';
      case FatigueLevel.high:
        return 'HIGH';
    }
  }
}

/// 세션 기록
class Session {
  final String id;
  final String patientId;
  final String therapistId;
  final String? interventionPlanId; // 중재 계획 ID
  final DateTime sessionDate;
  final int sessionNumber; // 세션 번호
  final List<ActivityRecord> activities; // 활동 기록
  final SessionObservations observations; // 관찰 소견
  final List<String> safetyIssues; // 안전 이슈
  final String? modifications; // 수정사항
  final String? nextSessionPlan; // 다음 세션 계획
  final String? autoGeneratedReport; // 자동 생성된 세션노트
  final DateTime createdAt;

  Session({
    required this.id,
    required this.patientId,
    required this.therapistId,
    this.interventionPlanId,
    required this.sessionDate,
    required this.sessionNumber,
    required this.activities,
    required this.observations,
    this.safetyIssues = const [],
    this.modifications,
    this.nextSessionPlan,
    this.autoGeneratedReport,
    required this.createdAt,
  });

  factory Session.fromFirestore(Map<String, dynamic> data, String id) {
    return Session(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      therapistId: data['therapist_id'] as String? ?? '',
      interventionPlanId: data['intervention_plan_id'] as String?,
      sessionDate:
          (data['session_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionNumber: (data['session_number'] as num?)?.toInt() ?? 1,
      activities: (data['activities'] as List?)
              ?.map((activity) =>
                  ActivityRecord.fromMap(activity as Map<String, dynamic>))
              .toList() ??
          [],
      observations: SessionObservations.fromMap(
          data['observations'] as Map<String, dynamic>? ?? {}),
      safetyIssues:
          List<String>.from(data['safety_issues'] as List? ?? []),
      modifications: data['modifications'] as String?,
      nextSessionPlan: data['next_session_plan'] as String?,
      autoGeneratedReport: data['auto_generated_report'] as String?,
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'therapist_id': therapistId,
      if (interventionPlanId != null) 'intervention_plan_id': interventionPlanId,
      'session_date': Timestamp.fromDate(sessionDate),
      'session_number': sessionNumber,
      'activities': activities.map((activity) => activity.toMap()).toList(),
      'observations': observations.toMap(),
      'safety_issues': safetyIssues,
      if (modifications != null) 'modifications': modifications,
      if (nextSessionPlan != null) 'next_session_plan': nextSessionPlan,
      if (autoGeneratedReport != null) 'auto_generated_report': autoGeneratedReport,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// 총 활동 시간 계산
  int get totalDuration {
    return activities.fold<int>(
        0, (total, activity) => total + activity.durationMinutes);
  }
}
