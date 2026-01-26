import '../constants/enums.dart';

/// SMART 목표 템플릿
class GoalTemplate {
  final String id;
  final String name;
  final GoalCategory category;
  final String specific;
  final String measurable;
  final String achievable;
  final String relevant;
  final int recommendedWeeks;
  final String example;

  GoalTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.specific,
    required this.measurable,
    required this.achievable,
    required this.relevant,
    required this.recommendedWeeks,
    required this.example,
  });
}

/// SMART 목표 템플릿 헬퍼
class GoalTemplatesHelper {
  /// 모든 목표 템플릿 목록
  static List<GoalTemplate> getAllTemplates() {
    return [
      // 기능적 목표 (Functional)
      GoalTemplate(
        id: 'func_01',
        name: '독립적 보행',
        category: GoalCategory.functional,
        specific: '보조 없이 독립적으로 10m 보행',
        measurable: '연속 10m 거리를 보조 도구 없이 걷기',
        achievable: '현재 보조 보행이 가능하며, 균형 능력 향상 중',
        relevant: '일상생활에서 독립성 증진에 필수적',
        recommendedWeeks: 8,
        example: '8주 내 보조 없이 독립적으로 10m 보행하기',
      ),
      GoalTemplate(
        id: 'func_02',
        name: '계단 오르기',
        category: GoalCategory.functional,
        specific: '난간을 잡고 10개 계단 오르내리기',
        measurable: '난간 잡고 연속 10개 계단 왕복',
        achievable: '현재 평지 보행이 안정적이며, 하지 근력 향상 중',
        relevant: '가정 및 학교 환경에서 이동성 증진',
        recommendedWeeks: 10,
        example: '10주 내 난간을 잡고 10개 계단 오르내리기',
      ),
      GoalTemplate(
        id: 'func_03',
        name: '균형 잡기',
        category: GoalCategory.functional,
        specific: '한 발로 10초간 균형 유지',
        measurable: '한 발 서기 자세로 10초 이상 유지',
        achievable: '현재 양발 서기는 안정적이며, 균형 훈련 진행 중',
        relevant: '낙상 예방 및 일상 활동 안전성 증진',
        recommendedWeeks: 6,
        example: '6주 내 한 발로 10초간 균형 잡기',
      ),
      
      // 신체적 목표 (Physical)
      GoalTemplate(
        id: 'phys_01',
        name: '근력 향상',
        category: GoalCategory.physical,
        specific: '상지 근력 등급 Fair에서 Good으로 향상',
        measurable: 'MMT(도수근력검사) 등급 Good 달성',
        achievable: '현재 Fair 등급이며, 꾸준한 근력 운동 진행 중',
        relevant: '일상생활 동작(들기, 밀기) 수행 능력 향상',
        recommendedWeeks: 12,
        example: '12주 내 상지 근력 등급 Good 달성하기',
      ),
      GoalTemplate(
        id: 'phys_02',
        name: '관절 가동범위',
        category: GoalCategory.physical,
        specific: '어깨 관절 굴곡 범위 120도에서 150도로 증가',
        measurable: '어깨 관절 굴곡 ROM 150도 달성',
        achievable: '현재 120도이며, 스트레칭 및 운동 진행 중',
        relevant: '옷 입기, 머리 빗기 등 일상 동작 수행',
        recommendedWeeks: 8,
        example: '8주 내 어깨 굴곡 범위 150도 달성하기',
      ),
      GoalTemplate(
        id: 'phys_03',
        name: '호흡 조절',
        category: GoalCategory.physical,
        specific: '수중에서 10초간 호흡 참기',
        measurable: '물속에서 10초 이상 호흡 정지 유지',
        achievable: '현재 5초 가능하며, 점진적 호흡 훈련 중',
        relevant: '수중재활 활동 참여 및 수영 기술 습득',
        recommendedWeeks: 6,
        example: '6주 내 수중에서 10초간 호흡 참기',
      ),
      
      // 사회적 목표 (Social)
      GoalTemplate(
        id: 'soc_01',
        name: '집단 활동 참여',
        category: GoalCategory.social,
        specific: '그룹 수업에 30분 이상 적극적으로 참여',
        measurable: '그룹 활동 30분 동안 80% 이상 과제 완수',
        achievable: '현재 개인 세션은 안정적이며, 또래 관계 형성 중',
        relevant: '사회성 발달 및 협동 능력 향상',
        recommendedWeeks: 8,
        example: '8주 내 그룹 수업 30분 적극 참여하기',
      ),
      GoalTemplate(
        id: 'soc_02',
        name: '의사소통',
        category: GoalCategory.social,
        specific: '치료사 지시를 듣고 3가지 동작 순서대로 수행',
        measurable: '언어 지시에 따라 3단계 동작 연속 수행',
        achievable: '현재 2단계 동작은 가능하며, 집중력 향상 중',
        relevant: '지시 이해 능력 및 학습 능력 향상',
        recommendedWeeks: 6,
        example: '6주 내 치료사 지시에 따라 3가지 동작 수행하기',
      ),
      
      // 인지적 목표 (Cognitive)
      GoalTemplate(
        id: 'cog_01',
        name: '주의 집중',
        category: GoalCategory.cognitive,
        specific: '한 가지 활동에 10분 이상 집중',
        measurable: '과제 수행 시 10분 동안 집중 유지',
        achievable: '현재 5분 집중 가능하며, 점진적 연장 중',
        relevant: '학습 능력 및 일상 과제 수행 능력 향상',
        recommendedWeeks: 8,
        example: '8주 내 한 가지 활동에 10분 이상 집중하기',
      ),
      GoalTemplate(
        id: 'cog_02',
        name: '순서 기억',
        category: GoalCategory.cognitive,
        specific: '5단계 동작 순서를 기억하고 수행',
        measurable: '치료사가 보여준 5단계 동작을 순서대로 재현',
        achievable: '현재 3단계는 가능하며, 기억력 훈련 진행 중',
        relevant: '일상생활 루틴 수행 및 학습 능력 향상',
        recommendedWeeks: 10,
        example: '10주 내 5단계 동작 순서 기억하고 수행하기',
      ),
    ];
  }

  /// 카테고리별 템플릿 필터링
  static List<GoalTemplate> getTemplatesByCategory(GoalCategory category) {
    return getAllTemplates().where((t) => t.category == category).toList();
  }

  /// 템플릿 ID로 검색
  static GoalTemplate? getTemplateById(String id) {
    try {
      return getAllTemplates().firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 카테고리 이름
  static String getCategoryDisplayName(GoalCategory category) {
    switch (category) {
      case GoalCategory.functional:
        return '기능적 목표';
      case GoalCategory.physical:
        return '신체적 목표';
      case GoalCategory.social:
        return '사회적 목표';
      case GoalCategory.cognitive:
        return '인지적 목표';
    }
  }

  /// 카테고리 설명
  static String getCategoryDescription(GoalCategory category) {
    switch (category) {
      case GoalCategory.functional:
        return '일상생활 동작 및 독립성';
      case GoalCategory.physical:
        return '근력, 유연성, 지구력 등';
      case GoalCategory.social:
        return '사회성, 의사소통, 협동';
      case GoalCategory.cognitive:
        return '집중력, 기억력, 문제해결';
    }
  }

  /// 우선순위 표시 이름
  static String getPriorityDisplayName(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.high:
        return '높음';
      case GoalPriority.medium:
        return '보통';
      case GoalPriority.low:
        return '낮음';
    }
  }

  /// 목표 상태 표시 이름
  static String getStatusDisplayName(GoalStatus status) {
    switch (status) {
      case GoalStatus.inProgress:
        return '진행 중';
      case GoalStatus.achieved:
        return '달성';
      case GoalStatus.revised:
        return '수정됨';
      case GoalStatus.cancelled:
        return '취소됨';
    }
  }
}
