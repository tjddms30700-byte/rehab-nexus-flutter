import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

/// 평가 항목
class AssessmentItem {
  final String itemId;
  final String question;
  final ScoringType scoringType;
  final double weight;
  final List<String>? options;

  AssessmentItem({
    required this.itemId,
    required this.question,
    required this.scoringType,
    this.weight = 1.0,
    this.options,
  });

  factory AssessmentItem.fromMap(Map<String, dynamic> data) {
    return AssessmentItem(
      itemId: data['item_id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      scoringType: _parseScoringType(data['scoring_type'] as String?),
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
      options: data['options'] != null
          ? List<String>.from(data['options'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'question': question,
      'scoring_type': _scoringTypeToString(scoringType),
      'weight': weight,
      if (options != null) 'options': options,
    };
  }

  static ScoringType _parseScoringType(String? type) {
    switch (type) {
      case 'SCALE_1_5':
        return ScoringType.scale1To5;
      case 'BINARY':
        return ScoringType.binary;
      case 'NUMERIC':
        return ScoringType.numeric;
      case 'TEXT':
        return ScoringType.text;
      default:
        return ScoringType.scale1To5;
    }
  }

  static String _scoringTypeToString(ScoringType type) {
    switch (type) {
      case ScoringType.scale1To5:
        return 'SCALE_1_5';
      case ScoringType.binary:
        return 'BINARY';
      case ScoringType.numeric:
        return 'NUMERIC';
      case ScoringType.text:
        return 'TEXT';
    }
  }
}

/// 평가 템플릿
class AssessmentTemplate {
  final String id;
  final String name;
  final String type; // 'STANDARD' or 'CUSTOM'
  final AssessmentCategory category;
  final String version;
  final List<AssessmentItem> items;
  final DateTime createdAt;

  AssessmentTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.version,
    required this.items,
    required this.createdAt,
  });

  factory AssessmentTemplate.fromFirestore(
      Map<String, dynamic> data, String id) {
    return AssessmentTemplate(
      id: id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'CUSTOM',
      category: _parseCategory(data['category'] as String?),
      version: data['version'] as String? ?? '1.0',
      items: (data['items'] as List?)
              ?.map((item) =>
                  AssessmentItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'category': _categoryToString(category),
      'version': version,
      'items': items.map((item) => item.toMap()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static AssessmentCategory _parseCategory(String? category) {
    switch (category) {
      case 'FUNCTIONAL':
        return AssessmentCategory.functional;
      case 'SENSORY':
        return AssessmentCategory.sensory;
      case 'BUOYANCY':
        return AssessmentCategory.buoyancy;
      case 'ROM':
        return AssessmentCategory.rom;
      default:
        return AssessmentCategory.functional;
    }
  }

  static String _categoryToString(AssessmentCategory category) {
    switch (category) {
      case AssessmentCategory.functional:
        return 'FUNCTIONAL';
      case AssessmentCategory.sensory:
        return 'SENSORY';
      case AssessmentCategory.buoyancy:
        return 'BUOYANCY';
      case AssessmentCategory.rom:
        return 'ROM';
    }
  }
}

/// 평가 항목 점수
class ItemScore {
  final String itemId;
  final dynamic score; // int, double, bool, or String
  final String? note;

  ItemScore({
    required this.itemId,
    required this.score,
    this.note,
  });

  factory ItemScore.fromMap(Map<String, dynamic> data) {
    return ItemScore(
      itemId: data['item_id'] as String? ?? '',
      score: data['score'],
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'score': score,
      if (note != null) 'note': note,
    };
  }
}

/// 평가 요약
class AssessmentSummary {
  final List<String> strengths;
  final List<String> challenges;
  final List<String> recommendations;

  AssessmentSummary({
    this.strengths = const [],
    this.challenges = const [],
    this.recommendations = const [],
  });

  factory AssessmentSummary.fromMap(Map<String, dynamic> data) {
    return AssessmentSummary(
      strengths: List<String>.from(data['strengths'] as List? ?? []),
      challenges: List<String>.from(data['challenges'] as List? ?? []),
      recommendations:
          List<String>.from(data['recommendations'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strengths': strengths,
      'challenges': challenges,
      'recommendations': recommendations,
    };
  }
}

/// 평가 기록
class Assessment {
  final String id;
  final String patientId;
  final String therapistId;
  final AssessmentType assessmentType;
  final String templateId;
  final DateTime assessmentDate;
  final List<ItemScore> scores;
  final double totalScore;
  final AssessmentSummary summary;
  final DateTime? nextAssessmentDue;
  final DateTime createdAt;

  Assessment({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.assessmentType,
    required this.templateId,
    required this.assessmentDate,
    required this.scores,
    required this.totalScore,
    required this.summary,
    this.nextAssessmentDue,
    required this.createdAt,
  });

  factory Assessment.fromFirestore(Map<String, dynamic> data, String id) {
    return Assessment(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      therapistId: data['therapist_id'] as String? ?? '',
      assessmentType: _parseAssessmentType(data['assessment_type'] as String?),
      templateId: data['template_id'] as String? ?? '',
      assessmentDate:
          (data['assessment_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scores: (data['scores'] as List?)
              ?.map((score) => ItemScore.fromMap(score as Map<String, dynamic>))
              .toList() ??
          [],
      totalScore: (data['total_score'] as num?)?.toDouble() ?? 0.0,
      summary: AssessmentSummary.fromMap(
          data['summary'] as Map<String, dynamic>? ?? {}),
      nextAssessmentDue:
          (data['next_assessment_due'] as Timestamp?)?.toDate(),
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'therapist_id': therapistId,
      'assessment_type': _assessmentTypeToString(assessmentType),
      'template_id': templateId,
      'assessment_date': Timestamp.fromDate(assessmentDate),
      'scores': scores.map((score) => score.toMap()).toList(),
      'total_score': totalScore,
      'summary': summary.toMap(),
      if (nextAssessmentDue != null)
        'next_assessment_due': Timestamp.fromDate(nextAssessmentDue!),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static AssessmentType _parseAssessmentType(String? type) {
    switch (type) {
      case 'INITIAL':
        return AssessmentType.initial;
      case 'REASSESSMENT':
        return AssessmentType.reassessment;
      case 'DISCHARGE':
        return AssessmentType.discharge;
      default:
        return AssessmentType.initial;
    }
  }

  static String _assessmentTypeToString(AssessmentType type) {
    switch (type) {
      case AssessmentType.initial:
        return 'INITIAL';
      case AssessmentType.reassessment:
        return 'REASSESSMENT';
      case AssessmentType.discharge:
        return 'DISCHARGE';
    }
  }
}
