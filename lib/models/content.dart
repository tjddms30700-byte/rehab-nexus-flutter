import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

/// 콘텐츠 모델 (중재 프로그램)
class Content {
  final String id;
  final String? organizationId; // null이면 글로벌 콘텐츠
  final String title; // 콘텐츠 제목
  final String description; // 설명
  final ContentType type; // 수중/일반/OT/PT
  final List<String> category; // 카테고리 (예: 균형, 근력, 호흡)
  final DifficultyLevel difficultyLevel; // 난이도 (1-5단계)
  final List<String> targetGoals; // 목표 태그
  final List<String> tags; // 일반 태그
  final int durationMinutes; // 소요 시간 (분)
  final List<String> equipment; // 필요 장비
  final List<String> contraindications; // 금기사항
  final List<String> precautions; // 주의사항
  final String instructions; // 수행 방법
  final List<MediaItem> media; // 미디어 (이미지/영상/PDF)
  final double rating; // 치료사 평점 (1-5)
  final DateTime createdAt;

  Content({
    required this.id,
    this.organizationId,
    required this.title,
    required this.description,
    required this.type,
    this.category = const [],
    required this.difficultyLevel,
    this.targetGoals = const [],
    this.tags = const [],
    required this.durationMinutes,
    this.equipment = const [],
    this.contraindications = const [],
    this.precautions = const [],
    required this.instructions,
    this.media = const [],
    this.rating = 0.0,
    required this.createdAt,
  });

  factory Content.fromFirestore(Map<String, dynamic> data, String id) {
    return Content(
      id: id,
      organizationId: data['organization_id'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: _parseContentType(data['type'] as String?),
      category: List<String>.from(data['category'] as List? ?? []),
      difficultyLevel: _parseDifficultyLevel(data['difficulty_level'] as String?),
      targetGoals: List<String>.from(data['target_goals'] as List? ?? []),
      tags: List<String>.from(data['tags'] as List? ?? []),
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 0,
      equipment: List<String>.from(data['equipment'] as List? ?? []),
      contraindications: List<String>.from(data['contraindications'] as List? ?? []),
      precautions: List<String>.from(data['precautions'] as List? ?? []),
      instructions: data['instructions'] as String? ?? '',
      media: (data['media'] as List?)
              ?.map((m) => MediaItem.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (organizationId != null) 'organization_id': organizationId,
      'title': title,
      'description': description,
      'type': _contentTypeToString(type),
      'category': category,
      'difficulty_level': _difficultyLevelToString(difficultyLevel),
      'target_goals': targetGoals,
      'tags': tags,
      'duration_minutes': durationMinutes,
      'equipment': equipment,
      'contraindications': contraindications,
      'precautions': precautions,
      'instructions': instructions,
      'media': media.map((m) => m.toMap()).toList(),
      'rating': rating,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static ContentType _parseContentType(String? type) {
    switch (type) {
      case 'AQUATIC':
        return ContentType.aquatic;
      case 'GENERAL':
        return ContentType.general;
      case 'OT':
        return ContentType.ot;
      case 'PT':
        return ContentType.pt;
      default:
        return ContentType.general;
    }
  }

  static String _contentTypeToString(ContentType type) {
    switch (type) {
      case ContentType.aquatic:
        return 'AQUATIC';
      case ContentType.general:
        return 'GENERAL';
      case ContentType.ot:
        return 'OT';
      case ContentType.pt:
        return 'PT';
    }
  }

  static DifficultyLevel _parseDifficultyLevel(String? level) {
    switch (level) {
      case 'LEVEL_1':
        return DifficultyLevel.level1;
      case 'LEVEL_2':
        return DifficultyLevel.level2;
      case 'LEVEL_3':
        return DifficultyLevel.level3;
      case 'LEVEL_4':
        return DifficultyLevel.level4;
      case 'LEVEL_5':
        return DifficultyLevel.level5;
      default:
        return DifficultyLevel.level3;
    }
  }

  static String _difficultyLevelToString(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.level1:
        return 'LEVEL_1';
      case DifficultyLevel.level2:
        return 'LEVEL_2';
      case DifficultyLevel.level3:
        return 'LEVEL_3';
      case DifficultyLevel.level4:
        return 'LEVEL_4';
      case DifficultyLevel.level5:
        return 'LEVEL_5';
    }
  }
}

/// 미디어 항목
class MediaItem {
  final String type; // 'IMAGE', 'VIDEO', 'PDF'
  final String url; // Storage URL

  MediaItem({
    required this.type,
    required this.url,
  });

  factory MediaItem.fromMap(Map<String, dynamic> data) {
    return MediaItem(
      type: data['type'] as String? ?? 'IMAGE',
      url: data['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'url': url,
    };
  }
}

/// 중재 계획 (Intervention Plan)
class InterventionPlan {
  final String id;
  final String patientId;
  final List<String> goalIds; // 연결된 목표 ID들
  final List<String> contentIds; // 선택된 콘텐츠 ID들
  final String frequency; // 빈도 (예: "주 3회")
  final int durationWeeks; // 기간 (주)
  final DateTime startDate;
  final DateTime endDate;
  final InterventionStatus status;
  final DateTime createdAt;

  InterventionPlan({
    required this.id,
    required this.patientId,
    this.goalIds = const [],
    this.contentIds = const [],
    required this.frequency,
    required this.durationWeeks,
    required this.startDate,
    required this.endDate,
    this.status = InterventionStatus.active,
    required this.createdAt,
  });

  factory InterventionPlan.fromFirestore(Map<String, dynamic> data, String id) {
    return InterventionPlan(
      id: id,
      patientId: data['patient_id'] as String? ?? '',
      goalIds: List<String>.from(data['goal_ids'] as List? ?? []),
      contentIds: List<String>.from(data['content_ids'] as List? ?? []),
      frequency: data['frequency'] as String? ?? '',
      durationWeeks: (data['duration_weeks'] as num?)?.toInt() ?? 0,
      startDate: (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status'] as String?),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'goal_ids': goalIds,
      'content_ids': contentIds,
      'frequency': frequency,
      'duration_weeks': durationWeeks,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'status': _statusToString(status),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static InterventionStatus _parseStatus(String? status) {
    switch (status) {
      case 'ACTIVE':
        return InterventionStatus.active;
      case 'COMPLETED':
        return InterventionStatus.completed;
      case 'PAUSED':
        return InterventionStatus.paused;
      default:
        return InterventionStatus.active;
    }
  }

  static String _statusToString(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.active:
        return 'ACTIVE';
      case InterventionStatus.completed:
        return 'COMPLETED';
      case InterventionStatus.paused:
        return 'PAUSED';
    }
  }
}
