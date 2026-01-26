import '../models/assessment.dart';
import '../constants/enums.dart';

/// 평가 템플릿 헬퍼 클래스
/// 21개 항목 수중재활 평가도구 템플릿 제공
class AssessmentTemplates {
  static final Map<String, AssessmentTemplate> _templates = {};

  static void _ensureTemplatesLoaded() {
    if (_templates.isNotEmpty) return;

    // 21개 항목 수중재활 평가 템플릿
    _templates['aqua_rehab_21'] = AssessmentTemplate(
      id: 'aqua_rehab_21',
      name: '수중재활 표준 평가 (21항목)',
      type: 'CUSTOM',
      category: AssessmentCategory.functional,
      version: '1.0',
      items: _create21Items(),
      createdAt: DateTime.now(),
    );

    // Berg Balance Scale 템플릿
    _templates['berg'] = AssessmentTemplate(
      id: 'berg',
      name: 'Berg Balance Scale',
      type: 'STANDARD',
      category: AssessmentCategory.functional,
      version: '1.0',
      items: [
        AssessmentItem(
          itemId: 'berg_01',
          question: '앉은 자세에서 선 자세로',
          scoringType: ScoringType.scale1To5,
        ),
        AssessmentItem(
          itemId: 'berg_02',
          question: '보조 없이 서있기',
          scoringType: ScoringType.scale1To5,
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  /// 21개 평가 항목 생성
  static List<AssessmentItem> _create21Items() {
    return [
      // 균형 (3개)
      AssessmentItem(
        itemId: 'balance_01',
        question: '물속에서 서 있는 자세 유지 능력',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
        options: [
          '1점: 전혀 불가능 (지지 필요)',
          '2점: 매우 어려움',
          '3점: 보통',
          '4점: 양호',
          '5점: 우수'
        ],
      ),
      AssessmentItem(
        itemId: 'balance_02',
        question: '물속 보행 시 균형 유지',
        scoringType: ScoringType.scale1To5,
        weight: 1.2,
        options: [
          '1점: 전혀 불가능',
          '2점: 매우 불안정',
          '3점: 보통',
          '4점: 양호',
          '5점: 우수'
        ],
      ),
      AssessmentItem(
        itemId: 'balance_03',
        question: '한 발로 서기 (물속)',
        scoringType: ScoringType.scale1To5,
        weight: 1.5,
        options: [
          '1점: 불가능',
          '2점: 3초 미만',
          '3점: 3-5초',
          '4점: 5-10초',
          '5점: 10초 이상'
        ],
      ),

      // 호흡 (2개)
      AssessmentItem(
        itemId: 'breathing_01',
        question: '물속에서 호흡 조절 능력',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
        options: [
          '1점: 매우 어려움',
          '2점: 어려움',
          '3점: 보통',
          '4점: 양호',
          '5점: 우수'
        ],
      ),
      AssessmentItem(
        itemId: 'breathing_02',
        question: '물속에서 날숨 조절',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
        options: [
          '1점: 불가능',
          '2점: 매우 짧음',
          '3점: 짧음',
          '4점: 적절함',
          '5점: 길게 가능'
        ],
      ),

      // 근력 (3개)
      AssessmentItem(
        itemId: 'strength_01',
        question: '상지 근력 (물속 팔 움직임)',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),
      AssessmentItem(
        itemId: 'strength_02',
        question: '하지 근력 (물속 다리 움직임)',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),
      AssessmentItem(
        itemId: 'strength_03',
        question: '코어 근력 (몸통 안정성)',
        scoringType: ScoringType.scale1To5,
        weight: 1.3,
      ),

      // 감각통합 (3개)
      AssessmentItem(
        itemId: 'sensory_01',
        question: '물의 온도 감각 인지',
        scoringType: ScoringType.scale1To5,
        weight: 0.8,
      ),
      AssessmentItem(
        itemId: 'sensory_02',
        question: '물의 압력 감각 (부력 적응)',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),
      AssessmentItem(
        itemId: 'sensory_03',
        question: '신체 위치 감각 (고유수용감각)',
        scoringType: ScoringType.scale1To5,
        weight: 1.2,
      ),

      // 참여도 (2개)
      AssessmentItem(
        itemId: 'participation_01',
        question: '치료 활동 참여 의지',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),
      AssessmentItem(
        itemId: 'participation_02',
        question: '치료사 지시 이해 및 수행',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),

      // 관절가동범위 (2개)
      AssessmentItem(
        itemId: 'rom_01',
        question: '어깨 관절 가동범위',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),
      AssessmentItem(
        itemId: 'rom_02',
        question: '고관절 가동범위',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),

      // 협응 (2개)
      AssessmentItem(
        itemId: 'coordination_01',
        question: '팔-다리 협응 동작',
        scoringType: ScoringType.scale1To5,
        weight: 1.2,
      ),
      AssessmentItem(
        itemId: 'coordination_02',
        question: '양측 동시 동작 수행',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),

      // 수중 특화 (2개)
      AssessmentItem(
        itemId: 'aquatic_01',
        question: '부력 적응도',
        scoringType: ScoringType.scale1To5,
        weight: 1.5,
      ),
      AssessmentItem(
        itemId: 'aquatic_02',
        question: '물 저항 활용 능력',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),

      // 안전/적응 (1개)
      AssessmentItem(
        itemId: 'safety_01',
        question: '물에 대한 공포/불안 수준 (역점수)',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),

      // 지구력 (1개)
      AssessmentItem(
        itemId: 'endurance_01',
        question: '수중 활동 지구력',
        scoringType: ScoringType.scale1To5,
        weight: 1.0,
      ),
    ];
  }

  /// 템플릿 가져오기
  static AssessmentTemplate? getTemplate(String id) {
    _ensureTemplatesLoaded();
    return _templates[id];
  }

  /// 모든 템플릿 가져오기
  static List<AssessmentTemplate> getAllTemplates() {
    _ensureTemplatesLoaded();
    return _templates.values.toList();
  }

  /// 21개 항목별 카테고리 정보
  static String getItemCategory(String itemId) {
    if (itemId.startsWith('balance_')) return '균형';
    if (itemId.startsWith('breathing_')) return '호흡';
    if (itemId.startsWith('strength_')) return '근력';
    if (itemId.startsWith('sensory_')) return '감각통합';
    if (itemId.startsWith('participation_')) return '참여도';
    if (itemId.startsWith('rom_')) return '관절가동범위';
    if (itemId.startsWith('coordination_')) return '협응';
    if (itemId.startsWith('aquatic_')) return '수중 특화';
    if (itemId.startsWith('safety_')) return '안전/적응';
    if (itemId.startsWith('endurance_')) return '지구력';
    return '기타';
  }
}
