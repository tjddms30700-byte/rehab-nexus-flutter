// 자체 개발 수중재활 평가도구 - 21개 항목
//
// 이 파일은 "개인별 등급 맞춤형 수중치료 콘텐츠 세분화 시스템" 특허 기반
// 자체 평가도구의 21개 세부 항목을 정의합니다.
//
// 평가 카테고리:
// - 균형 (Balance)
// - 호흡 (Breathing)
// - 근력 (Strength)
// - 감각통합 (Sensory Integration)
// - 참여도 (Participation)
// - 기타 수중 특화 항목

const aquaticAssessment21Items = [
  // === 균형 (Balance) 영역 ===
  {
    'item_id': 'balance_01',
    'question': '물속에서 서 있는 자세 유지 능력',
    'category': 'balance',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 전혀 불가능 (지지 필요)',
      '2점: 매우 어려움 (지속적 도움 필요)',
      '3점: 보통 (간헐적 도움 필요)',
      '4점: 양호 (최소 도움)',
      '5점: 우수 (독립적 수행)',
    ],
  },
  {
    'item_id': 'balance_02',
    'question': '물속 보행 시 균형 유지',
    'category': 'balance',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.2,
    'options': [
      '1점: 전혀 불가능',
      '2점: 매우 불안정',
      '3점: 보통 (일부 흔들림)',
      '4점: 양호',
      '5점: 우수 (안정적)',
    ],
  },
  {
    'item_id': 'balance_03',
    'question': '한 발로 서기 (물속)',
    'category': 'balance',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.5,
    'options': [
      '1점: 불가능',
      '2점: 3초 미만',
      '3점: 3-5초',
      '4점: 5-10초',
      '5점: 10초 이상',
    ],
  },

  // === 호흡 (Breathing) 영역 ===
  {
    'item_id': 'breathing_01',
    'question': '물속에서 호흡 조절 능력',
    'category': 'breathing',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 매우 어려움 (공포 반응)',
      '2점: 어려움 (불규칙한 호흡)',
      '3점: 보통',
      '4점: 양호 (규칙적 호흡)',
      '5점: 우수 (리드미컬한 호흡)',
    ],
  },
  {
    'item_id': 'breathing_02',
    'question': '물속에서 날숨 조절',
    'category': 'breathing',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 불가능',
      '2점: 매우 짧은 날숨',
      '3점: 짧은 날숨',
      '4점: 적절한 날숨',
      '5점: 긴 날숨 가능',
    ],
  },

  // === 근력 (Strength) 영역 ===
  {
    'item_id': 'strength_01',
    'question': '상지 근력 (물속 팔 움직임)',
    'category': 'strength',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 움직임 없음',
      '2점: 매우 약한 움직임',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수 (강한 저항 운동 가능)',
    ],
  },
  {
    'item_id': 'strength_02',
    'question': '하지 근력 (물속 다리 움직임)',
    'category': 'strength',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 움직임 없음',
      '2점: 매우 약한 움직임',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수',
    ],
  },
  {
    'item_id': 'strength_03',
    'question': '코어 근력 (몸통 안정성)',
    'category': 'strength',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.3,
    'options': [
      '1점: 매우 약함',
      '2점: 약함',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수',
    ],
  },

  // === 감각통합 (Sensory Integration) 영역 ===
  {
    'item_id': 'sensory_01',
    'question': '물의 온도 감각 인지',
    'category': 'sensory',
    'scoring_type': 'SCALE_1_5',
    'weight': 0.8,
    'options': [
      '1점: 인지 불가',
      '2점: 매우 둔함',
      '3점: 보통',
      '4점: 양호',
      '5점: 민감함',
    ],
  },
  {
    'item_id': 'sensory_02',
    'question': '물의 압력 감각 (부력 적응)',
    'category': 'sensory',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 적응 불가',
      '2점: 매우 어려움',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수 (빠른 적응)',
    ],
  },
  {
    'item_id': 'sensory_03',
    'question': '신체 위치 감각 (고유수용감각)',
    'category': 'sensory',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.2,
    'options': [
      '1점: 인지 불가',
      '2점: 매우 둔함',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수',
    ],
  },

  // === 참여도 (Participation) 영역 ===
  {
    'item_id': 'participation_01',
    'question': '치료 활동 참여 의지',
    'category': 'participation',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 거부',
      '2점: 매우 소극적',
      '3점: 보통',
      '4점: 적극적',
      '5점: 매우 적극적',
    ],
  },
  {
    'item_id': 'participation_02',
    'question': '치료사 지시 이해 및 수행',
    'category': 'participation',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 이해 불가',
      '2점: 매우 어려움',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수',
    ],
  },

  // === 관절가동범위 (ROM - Range of Motion) 영역 ===
  {
    'item_id': 'rom_01',
    'question': '어깨 관절 가동범위',
    'category': 'rom',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 매우 제한적 (< 30도)',
      '2점: 제한적 (30-60도)',
      '3점: 보통 (60-90도)',
      '4점: 양호 (90-120도)',
      '5점: 정상 (> 120도)',
    ],
  },
  {
    'item_id': 'rom_02',
    'question': '고관절 가동범위',
    'category': 'rom',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 매우 제한적',
      '2점: 제한적',
      '3점: 보통',
      '4점: 양호',
      '5점: 정상',
    ],
  },

  // === 협응 (Coordination) 영역 ===
  {
    'item_id': 'coordination_01',
    'question': '팔-다리 협응 동작',
    'category': 'coordination',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.2,
    'options': [
      '1점: 협응 불가',
      '2점: 매우 어려움',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수 (자연스러운 협응)',
    ],
  },
  {
    'item_id': 'coordination_02',
    'question': '양측 동시 동작 수행',
    'category': 'coordination',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 불가능',
      '2점: 매우 어려움',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수',
    ],
  },

  // === 수중 특화 영역 ===
  {
    'item_id': 'aquatic_01',
    'question': '부력 적응도 (물에 뜨는 능력)',
    'category': 'aquatic_specific',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.5,
    'options': [
      '1점: 두려움/거부',
      '2점: 매우 어려움',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수 (편안함)',
    ],
  },
  {
    'item_id': 'aquatic_02',
    'question': '물 저항 활용 능력',
    'category': 'aquatic_specific',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 인지 불가',
      '2점: 매우 어려움',
      '3점: 보통',
      '4점: 양호',
      '5점: 우수 (효율적 활용)',
    ],
  },

  // === 안전 및 적응 영역 ===
  {
    'item_id': 'safety_01',
    'question': '물에 대한 공포/불안 수준',
    'category': 'safety',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 매우 높음 (극도의 공포)',
      '2점: 높음 (심한 불안)',
      '3점: 보통',
      '4점: 낮음 (약간 불안)',
      '5점: 없음 (편안함)',
    ],
  },
  {
    'item_id': 'endurance_01',
    'question': '수중 활동 지구력',
    'category': 'endurance',
    'scoring_type': 'SCALE_1_5',
    'weight': 1.0,
    'options': [
      '1점: 5분 미만',
      '2점: 5-10분',
      '3점: 10-20분',
      '4점: 20-30분',
      '5점: 30분 이상',
    ],
  },
];

/// 평가 항목 카테고리 한글 이름
const categoryDisplayNames = {
  'balance': '균형',
  'breathing': '호흡',
  'strength': '근력',
  'sensory': '감각통합',
  'participation': '참여도',
  'rom': '관절가동범위',
  'coordination': '협응',
  'aquatic_specific': '수중 특화',
  'safety': '안전/적응',
  'endurance': '지구력',
};

/// 평가 점수 → 난이도 레벨 변환
/// 
/// 총점 기준:
/// - 21-42점: LEVEL_1 (매우 낮음)
/// - 43-63점: LEVEL_2 (낮음)
/// - 64-84점: LEVEL_3 (보통)
/// - 85-105점: LEVEL_4 (높음)
String scoreToDifficultyLevel(double totalScore) {
  if (totalScore < 43) return 'LEVEL_1';
  if (totalScore < 64) return 'LEVEL_2';
  if (totalScore < 85) return 'LEVEL_3';
  if (totalScore < 106) return 'LEVEL_4';
  return 'LEVEL_5';
}

/// 난이도 레벨 한글 이름
const difficultyLevelDisplayNames = {
  'LEVEL_1': '1단계 (입문)',
  'LEVEL_2': '2단계 (초급)',
  'LEVEL_3': '3단계 (중급)',
  'LEVEL_4': '4단계 (중상급)',
  'LEVEL_5': '5단계 (상급)',
};
