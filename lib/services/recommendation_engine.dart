import 'package:flutter/foundation.dart';
import '../models/content.dart';
import '../models/assessment.dart';
import '../models/patient.dart';
import '../models/goal.dart';
import '../constants/enums.dart';

/// 추천 결과
class RecommendationResult {
  final Content content;
  final double score; // 추천 점수 (0-100)
  final List<String> reasons; // 추천 이유
  final List<String> warnings; // 주의사항

  RecommendationResult({
    required this.content,
    required this.score,
    required this.reasons,
    this.warnings = const [],
  });
}

/// 콘텐츠 추천 엔진 (특허 기반 알고리즘)
/// 
/// "개인별 등급 맞춤형 수중치료 콘텐츠 세분화 시스템" 특허 구현
/// - 평가 점수 기반 난이도 매칭
/// - 목표-콘텐츠 태그 매칭
/// - 금기사항 자동 필터링
/// - 콘텐츠 평점 반영
class RecommendationEngine {
  /// Phase 1: 룰 기반 추천 (MVP)
  /// 
  /// 입력:
  /// - 환자 정보 (진단명, 의료 이력)
  /// - 최신 평가 결과 (21개 항목 점수)
  /// - 설정된 목표 (SMART 목표)
  /// - 콘텐츠 풀
  /// 
  /// 출력:
  /// - 추천 콘텐츠 목록 (점수순)
  /// - 추천 이유
  /// - 주의사항
  static List<RecommendationResult> recommendContents({
    required Patient patient,
    required Assessment latestAssessment,
    required List<Goal> activeGoals,
    required List<Content> contentPool,
    int limit = 20,
  }) {
    if (kDebugMode) {
      debugPrint('🤖 추천 엔진 시작');
      debugPrint('   - 환자: ${patient.name}');
      debugPrint('   - 평가 총점: ${latestAssessment.totalScore}');
      debugPrint('   - 활성 목표: ${activeGoals.length}개');
      debugPrint('   - 콘텐츠 풀: ${contentPool.length}개');
    }

    // 1. 평가 점수 → 난이도 레벨 변환
    final patientLevel = _scoreToDifficultyLevel(latestAssessment.totalScore);

    // 2. 목표 태그 추출
    final goalTags = activeGoals.map((g) => _goalCategoryToTag(g.category)).toList();

    // 3. 진단명 추출
    final diagnosis = patient.diagnosis;

    // 4. 각 콘텐츠 점수 계산
    final results = contentPool.map((content) {
      final scoreData = _calculateRecommendationScore(
        content: content,
        patientLevel: patientLevel,
        goalTags: goalTags,
        diagnosis: diagnosis,
        assessmentScores: latestAssessment.scores,
      );

      return RecommendationResult(
        content: content,
        score: scoreData['score'] as double,
        reasons: scoreData['reasons'] as List<String>,
        warnings: scoreData['warnings'] as List<String>,
      );
    }).toList();

    // 5. 점수 기준 정렬 (높은 순)
    results.sort((a, b) => b.score.compareTo(a.score));

    // 6. 점수 0 이상만 반환
    final validResults = results.where((r) => r.score > 0).take(limit).toList();

    if (kDebugMode) {
      debugPrint('✅ 추천 완료: ${validResults.length}개 콘텐츠');
      if (validResults.isNotEmpty) {
        debugPrint('   Top 3:');
        for (var i = 0; i < validResults.length && i < 3; i++) {
          debugPrint('   ${i + 1}. ${validResults[i].content.title} (${validResults[i].score.toStringAsFixed(1)}점)');
        }
      }
    }

    return validResults;
  }

  /// 평가 점수 → 난이도 레벨 변환
  static DifficultyLevel _scoreToDifficultyLevel(double totalScore) {
    if (totalScore < 43) return DifficultyLevel.level1;
    if (totalScore < 64) return DifficultyLevel.level2;
    if (totalScore < 85) return DifficultyLevel.level3;
    if (totalScore < 106) return DifficultyLevel.level4;
    return DifficultyLevel.level5;
  }

  /// 목표 카테고리 → 태그 변환
  static String _goalCategoryToTag(GoalCategory category) {
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

  /// 추천 점수 계산 (룰 기반)
  static Map<String, dynamic> _calculateRecommendationScore({
    required Content content,
    required DifficultyLevel patientLevel,
    required List<String> goalTags,
    required List<String> diagnosis,
    required List<ItemScore> assessmentScores,
  }) {
    double score = 0.0;
    final reasons = <String>[];
    final warnings = <String>[];

    // === 1. 난이도 매칭 (30점) ===
    final levelDiff = (content.difficultyLevel.index - patientLevel.index).abs();
    final levelScore = (3 - levelDiff.clamp(0, 3)) * 10.0;
    score += levelScore;

    if (levelDiff == 0) {
      reasons.add('현재 레벨에 정확히 맞는 난이도입니다');
    } else if (levelDiff == 1) {
      reasons.add('한 단계 ${content.difficultyLevel.index > patientLevel.index ? "높은" : "낮은"} 난이도로 적절합니다');
    } else if (levelDiff >= 2) {
      warnings.add('난이도 차이가 큽니다. 치료사 판단이 필요합니다');
    }

    // === 2. 목표 태그 매칭 (40점) ===
    if (goalTags.isNotEmpty) {
      final matchingGoals = content.targetGoals.where((tag) => goalTags.contains(tag)).toList();
      final goalMatchScore = (matchingGoals.length / goalTags.length.clamp(1, 10)) * 40.0;
      score += goalMatchScore;

      if (matchingGoals.isNotEmpty) {
        reasons.add('설정된 목표 ${matchingGoals.length}개와 연결됩니다');
      }
    }

    // === 3. 평가 카테고리 매칭 (10점) ===
    final weakCategories = _findWeakCategories(assessmentScores);
    final categoryMatches = content.category.where((cat) => weakCategories.contains(cat)).toList();
    if (categoryMatches.isNotEmpty) {
      score += 10.0;
      reasons.add('약점 영역 ${categoryMatches.join(", ")}을 보완합니다');
    }

    // === 4. 콘텐츠 평점 (10점) ===
    final ratingScore = (content.rating / 5.0) * 10.0;
    score += ratingScore;
    if (content.rating >= 4.5) {
      reasons.add('다른 치료사들의 높은 평가 (${content.rating.toStringAsFixed(1)}점)');
    }

    // === 5. 콘텐츠 타입 보너스 (10점) ===
    if (content.type == ContentType.aquatic) {
      score += 10.0;
      reasons.add('수중재활 특화 콘텐츠입니다');
    }

    // === 6. 금기사항 체크 (-100점) ===
    final hasContraindication = _checkContraindications(content, diagnosis);
    if (hasContraindication['has'] as bool) {
      score -= 100.0;
      warnings.add('⚠️ 금기사항: ${hasContraindication['reason']}');
    }

    return {
      'score': score.clamp(0.0, 100.0),
      'reasons': reasons,
      'warnings': warnings,
    };
  }

  /// 약점 카테고리 찾기 (평가 점수 2점 이하)
  static List<String> _findWeakCategories(List<ItemScore> scores) {
    final weakItems = <String>[];

    for (var score in scores) {
      if (score.score is num && (score.score as num) <= 2.0) {
        // 항목 ID에서 카테고리 추출 (예: balance_01 → balance)
        final category = score.itemId.split('_')[0];
        if (!weakItems.contains(category)) {
          weakItems.add(category);
        }
      }
    }

    return weakItems;
  }

  /// 금기사항 체크
  static Map<String, dynamic> _checkContraindications(
    Content content,
    List<String> diagnosis,
  ) {
    for (var diag in diagnosis) {
      for (var contraindication in content.contraindications) {
        if (contraindication.toLowerCase().contains(diag.toLowerCase()) ||
            diag.toLowerCase().contains(contraindication.toLowerCase())) {
          return {
            'has': true,
            'reason': '$diag 환자에게 $contraindication 금기',
          };
        }
      }
    }

    return {'has': false, 'reason': ''};
  }

  /// Phase 2: 피드백 반영 적응형 추천 (향후 구현)
  /// 
  /// 추가 고려사항:
  /// - 보호자 수행 피드백 (난이도 평가)
  /// - 치료사 세션 기록 (환자 반응)
  /// - 과거 프로그램 효과성
  /// - 수행률 패턴
  static List<RecommendationResult> recommendContentsAdaptive({
    required Patient patient,
    required Assessment latestAssessment,
    required List<Goal> activeGoals,
    required List<Content> contentPool,
    required List<Map<String, dynamic>> feedbackHistory, // 피드백 이력
    int limit = 20,
  }) {
    // TODO: Phase 2 구현
    // 1. 룰 기반 추천 실행
    final baseRecommendations = recommendContents(
      patient: patient,
      latestAssessment: latestAssessment,
      activeGoals: activeGoals,
      contentPool: contentPool,
      limit: limit * 2, // 더 많이 가져와서 필터링
    );

    // 2. 피드백 데이터 분석
    // - 보호자가 "어렵다"고 평가한 콘텐츠 → 점수 감소
    // - 높은 수행률의 콘텐츠 → 점수 증가
    // - 긍정적 반응의 콘텐츠 → 점수 증가

    // 3. 점수 재조정 및 재정렬

    return baseRecommendations.take(limit).toList();
  }

  /// Phase 3: ML 기반 예측 (향후 구현)
  /// 
  /// ML 모델 활용:
  /// - 목표 달성 확률 예측
  /// - 최적 콘텐츠 조합 추천
  /// - 진행 속도 예측
  static Future<List<RecommendationResult>> recommendContentsML({
    required Patient patient,
    required Assessment latestAssessment,
    required List<Goal> activeGoals,
    required List<Content> contentPool,
    int limit = 20,
  }) async {
    // TODO: Phase 3 구현
    // ML 모델 서버 호출 또는 온디바이스 추론
    throw UnimplementedError('ML 기반 추천은 Phase 3에서 구현됩니다');
  }
}
