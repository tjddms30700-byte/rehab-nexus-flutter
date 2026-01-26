import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

/// SMART 목표 기준
class SmartCriteria {
  final String specific; // 구체적
  final String measurable; // 측정 가능
  final String achievable; // 달성 가능
  final String relevant; // 관련성
  final DateTime timeBound; // 기한

  SmartCriteria({
    required this.specific,
    required this.measurable,
    required this.achievable,
    required this.relevant,
    required this.timeBound,
  });

  factory SmartCriteria.fromMap(Map<String, dynamic> data) {
    return SmartCriteria(
      specific: data['specific'] as String? ?? '',
      measurable: data['measurable'] as String? ?? '',
      achievable: data['achievable'] as String? ?? '',
      relevant: data['relevant'] as String? ?? '',
      timeBound: (data['time_bound'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'specific': specific,
      'measurable': measurable,
      'achievable': achievable,
      'relevant': relevant,
      'time_bound': Timestamp.fromDate(timeBound),
    };
  }
}

/// 목표 모델
class Goal {
  final String id;
  final String patientId;
  final String therapistId;
  final String? assessmentId; // 연결된 평가 ID
  final String goalText; // 목표 텍스트
  final SmartCriteria smartCriteria; // SMART 기준
  final GoalCategory category; // 목표 카테고리
  final GoalPriority priority; // 우선순위
  final DateTime targetDate; // 목표 달성 예정일
  final GoalStatus status; // 목표 상태
  final double progressPercentage; // 진행률 (0-100)
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.patientId,
    required this.therapistId,
    this.assessmentId,
    required this.goalText,
    required this.smartCriteria,
    required this.category,
    this.priority = GoalPriority.medium,
    required this.targetDate,
    this.status = GoalStatus.inProgress,
    this.progressPercentage = 0.0,
    required this.createdAt,
  });

  factory Goal.fromFirestore(Map<String, dynamic> data, String id) {
    return Goal(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      therapistId: data['therapist_id'] as String? ?? '',
      assessmentId: data['assessment_id'] as String?,
      goalText: data['goal_text'] as String? ?? '',
      smartCriteria: SmartCriteria.fromMap(
          data['smart_criteria'] as Map<String, dynamic>? ?? {}),
      category: _parseCategory(data['category'] as String?),
      priority: _parsePriority(data['priority'] as String?),
      targetDate:
          (data['target_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status'] as String?),
      progressPercentage:
          (data['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'therapist_id': therapistId,
      if (assessmentId != null) 'assessment_id': assessmentId,
      'goal_text': goalText,
      'smart_criteria': smartCriteria.toMap(),
      'category': _categoryToString(category),
      'priority': _priorityToString(priority),
      'target_date': Timestamp.fromDate(targetDate),
      'status': _statusToString(status),
      'progress_percentage': progressPercentage,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static GoalCategory _parseCategory(String? category) {
    switch (category) {
      case 'FUNCTIONAL':
        return GoalCategory.functional;
      case 'SOCIAL':
        return GoalCategory.social;
      case 'COGNITIVE':
        return GoalCategory.cognitive;
      case 'PHYSICAL':
        return GoalCategory.physical;
      default:
        return GoalCategory.functional;
    }
  }

  static String _categoryToString(GoalCategory category) {
    switch (category) {
      case GoalCategory.functional:
        return 'FUNCTIONAL';
      case GoalCategory.social:
        return 'SOCIAL';
      case GoalCategory.cognitive:
        return 'COGNITIVE';
      case GoalCategory.physical:
        return 'PHYSICAL';
    }
  }

  static GoalPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'HIGH':
        return GoalPriority.high;
      case 'MEDIUM':
        return GoalPriority.medium;
      case 'LOW':
        return GoalPriority.low;
      default:
        return GoalPriority.medium;
    }
  }

  static String _priorityToString(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.high:
        return 'HIGH';
      case GoalPriority.medium:
        return 'MEDIUM';
      case GoalPriority.low:
        return 'LOW';
    }
  }

  static GoalStatus _parseStatus(String? status) {
    switch (status) {
      case 'IN_PROGRESS':
        return GoalStatus.inProgress;
      case 'ACHIEVED':
        return GoalStatus.achieved;
      case 'REVISED':
        return GoalStatus.revised;
      case 'CANCELLED':
        return GoalStatus.cancelled;
      default:
        return GoalStatus.inProgress;
    }
  }

  static String _statusToString(GoalStatus status) {
    switch (status) {
      case GoalStatus.inProgress:
        return 'IN_PROGRESS';
      case GoalStatus.achieved:
        return 'ACHIEVED';
      case GoalStatus.revised:
        return 'REVISED';
      case GoalStatus.cancelled:
        return 'CANCELLED';
    }
  }

  /// 진행률 업데이트
  Goal updateProgress(double newProgress) {
    return Goal(
      id: id,
      patientId: patientId,
      therapistId: therapistId,
      assessmentId: assessmentId,
      goalText: goalText,
      smartCriteria: smartCriteria,
      category: category,
      priority: priority,
      targetDate: targetDate,
      status: newProgress >= 100 ? GoalStatus.achieved : status,
      progressPercentage: newProgress.clamp(0.0, 100.0),
      createdAt: createdAt,
    );
  }
}
