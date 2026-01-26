import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content.dart';
import '../constants/enums.dart';

/// 콘텐츠 관리 서비스
class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 콘텐츠 목록 조회 (기관 전용 + 글로벌)
  Future<List<Content>> getContents(String? organizationId) async {
    try {
      // 글로벌 콘텐츠
      final globalSnapshot = await _firestore
          .collection('contents')
          .where('organization_id', isNull: true)
          .get();

      final contents = globalSnapshot.docs
          .map((doc) => Content.fromFirestore(doc.data(), doc.id))
          .toList();

      // 기관 전용 콘텐츠 (있을 경우)
      if (organizationId != null) {
        final orgSnapshot = await _firestore
            .collection('contents')
            .where('organization_id', isEqualTo: organizationId)
            .get();

        contents.addAll(orgSnapshot.docs
            .map((doc) => Content.fromFirestore(doc.data(), doc.id)));
      }

      return contents;
    } catch (e) {
      throw Exception('콘텐츠 조회 실패: $e');
    }
  }

  /// 콘텐츠 스트림 조회
  Stream<List<Content>> getContentsStream(String? organizationId) {
    return _firestore
        .collection('contents')
        .snapshots()
        .map((snapshot) {
      final contents = snapshot.docs
          .map((doc) => Content.fromFirestore(doc.data(), doc.id))
          .toList();

      // 글로벌 + 기관 전용 필터링
      return contents.where((content) {
        return content.organizationId == null ||
            content.organizationId == organizationId;
      }).toList();
    });
  }

  /// 특정 콘텐츠 조회
  Future<Content?> getContent(String contentId) async {
    try {
      final doc = await _firestore.collection('contents').doc(contentId).get();
      if (!doc.exists) return null;
      return Content.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('콘텐츠 조회 실패: $e');
    }
  }

  /// 콘텐츠 생성
  Future<String> createContent(Content content) async {
    try {
      final docRef = await _firestore.collection('contents').add(content.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('콘텐츠 생성 실패: $e');
    }
  }

  /// 콘텐츠 업데이트
  Future<void> updateContent(String contentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('contents').doc(contentId).update(data);
    } catch (e) {
      throw Exception('콘텐츠 업데이트 실패: $e');
    }
  }

  /// 콘텐츠 삭제
  Future<void> deleteContent(String contentId) async {
    try {
      await _firestore.collection('contents').doc(contentId).delete();
    } catch (e) {
      throw Exception('콘텐츠 삭제 실패: $e');
    }
  }

  /// 난이도별 콘텐츠 필터링
  Future<List<Content>> getContentsByLevel(
    String? organizationId,
    DifficultyLevel level,
  ) async {
    final allContents = await getContents(organizationId);
    return allContents.where((content) => content.difficultyLevel == level).toList();
  }

  /// 타입별 콘텐츠 필터링
  Future<List<Content>> getContentsByType(
    String? organizationId,
    ContentType type,
  ) async {
    final allContents = await getContents(organizationId);
    return allContents.where((content) => content.type == type).toList();
  }

  /// 콘텐츠 검색 (제목, 설명, 태그)
  Future<List<Content>> searchContents(
    String? organizationId,
    String query,
  ) async {
    final allContents = await getContents(organizationId);
    final lowercaseQuery = query.toLowerCase();

    return allContents.where((content) {
      return content.title.toLowerCase().contains(lowercaseQuery) ||
          content.description.toLowerCase().contains(lowercaseQuery) ||
          content.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// 목표 태그 기반 콘텐츠 필터링
  Future<List<Content>> getContentsByGoalTags(
    String? organizationId,
    List<String> goalTags,
  ) async {
    final allContents = await getContents(organizationId);

    return allContents.where((content) {
      return content.targetGoals.any((tag) => goalTags.contains(tag));
    }).toList();
  }

  /// 금기사항 체크 (환자 진단명과 콘텐츠 금기사항 비교)
  bool hasContraindication(Content content, List<String> patientDiagnosis) {
    // 환자의 진단명이 콘텐츠의 금기사항에 포함되어 있는지 확인
    for (var diagnosis in patientDiagnosis) {
      for (var contraindication in content.contraindications) {
        if (contraindication.toLowerCase().contains(diagnosis.toLowerCase()) ||
            diagnosis.toLowerCase().contains(contraindication.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }

  /// 추천 점수 계산 (간단한 룰 기반)
  double calculateRecommendationScore(
    Content content,
    DifficultyLevel patientLevel,
    List<String> goalTags,
    List<String> patientDiagnosis,
  ) {
    double score = 0.0;

    // 1. 난이도 매칭 (30점)
    final levelDiff = (content.difficultyLevel.index - patientLevel.index).abs();
    score += (3 - levelDiff.clamp(0, 3)) * 10.0;

    // 2. 목표 태그 매칭 (40점)
    final matchingGoals = content.targetGoals.where((tag) => goalTags.contains(tag)).length;
    score += (matchingGoals / goalTags.length.clamp(1, 10)) * 40.0;

    // 3. 콘텐츠 평점 (20점)
    score += (content.rating / 5.0) * 20.0;

    // 4. 금기사항 체크 (-100점)
    if (hasContraindication(content, patientDiagnosis)) {
      score -= 100.0;
    }

    return score;
  }

  /// 추천 콘텐츠 목록 (점수 기반 정렬)
  Future<List<Content>> getRecommendedContents(
    String? organizationId,
    DifficultyLevel patientLevel,
    List<String> goalTags,
    List<String> patientDiagnosis, {
    int limit = 20,
  }) async {
    final allContents = await getContents(organizationId);

    // 각 콘텐츠에 점수 부여
    final scoredContents = allContents.map((content) {
      final score = calculateRecommendationScore(
        content,
        patientLevel,
        goalTags,
        patientDiagnosis,
      );
      return {'content': content, 'score': score};
    }).toList();

    // 점수 기준 정렬 (높은 순)
    scoredContents.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // 점수가 0 이상인 콘텐츠만 반환
    return scoredContents
        .where((item) => (item['score'] as double) > 0)
        .take(limit)
        .map((item) => item['content'] as Content)
        .toList();
  }
}
