import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/assessment_templates.dart';

/// Firebase 초기 데이터 생성 유틸리티
class FirebaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 21개 평가 항목 템플릿 생성
  Future<void> createAssessmentTemplate() async {
    try {
      // 자체 수중재활 평가도구 템플릿
      final templateRef = await _firestore.collection('assessment_templates').add({
        'name': '수중재활 자체 평가도구 (21개 항목)',
        'type': 'CUSTOM',
        'category': 'FUNCTIONAL',
        'version': '1.0',
        'items': aquaticAssessment21Items,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ 평가 템플릿 생성 완료: ${templateRef.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 평가 템플릿 생성 실패: $e');
      }
      rethrow;
    }
  }

  /// 샘플 콘텐츠 (수중재활 프로그램) 생성
  Future<void> createSampleContents() async {
    final sampleContents = [
      // === LEVEL 1: 입문 단계 ===
      {
        'title': '물 적응 훈련 - 기본',
        'description': '물에 대한 두려움을 줄이고 기본적인 물 적응 능력을 키웁니다.',
        'type': 'AQUATIC',
        'category': ['balance', 'safety', 'sensory'],
        'difficulty_level': 'LEVEL_1',
        'target_goals': ['FUNCTIONAL', 'PHYSICAL'],
        'tags': ['입문', '물 적응', '안전', '초보자'],
        'duration_minutes': 20,
        'equipment': ['구명조끼', '부력 보조도구'],
        'contraindications': ['물 공포증(심각)', '최근 수술 이력'],
        'precautions': ['치료사 밀착 지도 필수', '얕은 물에서 시작'],
        'instructions': '''
1. 풀장 가장자리 잡고 서기 (5분)
2. 천천히 물속 걷기 연습 (5분)
3. 물에 손 담그고 얼굴 가까이 가져가기 (5분)
4. 부력 보조도구로 물에 뜨는 연습 (5분)
        ''',
        'media': [],
        'rating': 4.5,
      },
      {
        'title': '호흡 조절 기초',
        'description': '물속에서 호흡을 조절하는 기초 훈련입니다.',
        'type': 'AQUATIC',
        'category': ['breathing', 'sensory'],
        'difficulty_level': 'LEVEL_1',
        'target_goals': ['PHYSICAL'],
        'tags': ['호흡', '기초', '입문'],
        'duration_minutes': 15,
        'equipment': ['없음'],
        'contraindications': ['호흡기 질환', '천식(심각)'],
        'precautions': ['환기가 잘 되는 공간', '무리하지 않기'],
        'instructions': '''
1. 풀장 가장자리에서 숨 들이쉬기-내쉬기 (3분)
2. 물속에 입만 담그고 날숨 연습 (5분)
3. 물속에 코까지 담그고 천천히 날숨 (5분)
4. 리듬에 맞춰 호흡 조절하기 (2분)
        ''',
        'media': [],
        'rating': 4.7,
      },

      // === LEVEL 2: 초급 단계 ===
      {
        'title': '물속 균형 잡기',
        'description': '물속에서 균형을 유지하며 서 있는 훈련입니다.',
        'type': 'AQUATIC',
        'category': ['balance', 'strength'],
        'difficulty_level': 'LEVEL_2',
        'target_goals': ['FUNCTIONAL', 'PHYSICAL'],
        'tags': ['균형', '초급', '코어'],
        'duration_minutes': 25,
        'equipment': ['풀 누들(pool noodle)'],
        'contraindications': ['어지럼증', '심한 균형 장애'],
        'precautions': ['낙상 주의', '치료사 근접 지원'],
        'instructions': '''
1. 양발로 서서 균형 잡기 (5분)
2. 한 발씩 들어 올리기 (각 5분)
3. 풀 누들을 이용한 균형 훈련 (10분)
4. 천천히 방향 전환하며 균형 유지 (5분)
        ''',
        'media': [],
        'rating': 4.3,
      },
      {
        'title': '팔 움직임 기초',
        'description': '물의 저항을 이용한 상지 근력 강화 운동입니다.',
        'type': 'AQUATIC',
        'category': ['strength', 'coordination'],
        'difficulty_level': 'LEVEL_2',
        'target_goals': ['PHYSICAL'],
        'tags': ['근력', '상지', '초급'],
        'duration_minutes': 20,
        'equipment': ['물속 아령', '부력 밴드'],
        'contraindications': ['어깨 탈구 이력', '최근 상지 골절'],
        'precautions': ['무리한 동작 금지', '통증 시 중단'],
        'instructions': '''
1. 팔을 앞뒤로 움직이기 (5분)
2. 팔을 좌우로 벌리고 모으기 (5분)
3. 물속 아령으로 팔 굽히기 (5분)
4. 원을 그리며 팔 돌리기 (5분)
        ''',
        'media': [],
        'rating': 4.4,
      },

      // === LEVEL 3: 중급 단계 ===
      {
        'title': '물속 보행 훈련',
        'description': '다양한 방향으로 걸으며 균형과 협응력을 향상시킵니다.',
        'type': 'AQUATIC',
        'category': ['balance', 'coordination', 'endurance'],
        'difficulty_level': 'LEVEL_3',
        'target_goals': ['FUNCTIONAL', 'PHYSICAL'],
        'tags': ['보행', '중급', '협응'],
        'duration_minutes': 30,
        'equipment': ['없음'],
        'contraindications': ['하지 골절', '심각한 관절염'],
        'precautions': ['미끄럼 주의', '속도 조절'],
        'instructions': '''
1. 앞으로 걷기 (10분)
2. 뒤로 걷기 (5분)
3. 옆으로 걷기 (5분)
4. 지그재그로 걷기 (5분)
5. 빠른 속도로 걷기 (5분)
        ''',
        'media': [],
        'rating': 4.6,
      },
      {
        'title': '코어 근력 강화',
        'description': '물의 저항을 이용한 복부 및 등 근육 강화 운동입니다.',
        'type': 'AQUATIC',
        'category': ['strength', 'coordination'],
        'difficulty_level': 'LEVEL_3',
        'target_goals': ['PHYSICAL'],
        'tags': ['코어', '근력', '중급'],
        'duration_minutes': 25,
        'equipment': ['풀 누들', '부력 벨트'],
        'contraindications': ['허리 디스크', '최근 복부 수술'],
        'precautions': ['요추 보호', '무리한 비틀기 금지'],
        'instructions': '''
1. 물속에서 무릎 가슴으로 당기기 (5분)
2. 다리 좌우로 흔들기 (5분)
3. 풀 누들로 몸통 비틀기 (10분)
4. 부력 벨트로 플랭크 자세 (5분)
        ''',
        'media': [],
        'rating': 4.5,
      },

      // === LEVEL 4: 중상급 단계 ===
      {
        'title': '물속 점프 및 착지',
        'description': '폭발적인 근력과 균형 능력을 향상시키는 고강도 훈련입니다.',
        'type': 'AQUATIC',
        'category': ['strength', 'balance', 'coordination'],
        'difficulty_level': 'LEVEL_4',
        'target_goals': ['PHYSICAL'],
        'tags': ['고강도', '점프', '중상급'],
        'duration_minutes': 20,
        'equipment': ['없음'],
        'contraindications': ['무릎 인대 손상', '골다공증'],
        'precautions': ['충격 흡수 주의', '무리한 반복 금지'],
        'instructions': '''
1. 제자리에서 가볍게 점프 (5분)
2. 앞으로 점프하며 착지 (5분)
3. 180도 회전 점프 (5분)
4. 한 발로 착지하기 (5분)
        ''',
        'media': [],
        'rating': 4.2,
      },

      // === LEVEL 5: 상급 단계 ===
      {
        'title': '고강도 수중 인터벌',
        'description': '심폐 지구력과 전신 근력을 동시에 향상시키는 고강도 훈련입니다.',
        'type': 'AQUATIC',
        'category': ['endurance', 'strength', 'coordination'],
        'difficulty_level': 'LEVEL_5',
        'target_goals': ['PHYSICAL'],
        'tags': ['고강도', '인터벌', '상급'],
        'duration_minutes': 30,
        'equipment': ['물속 아령', '저항 밴드'],
        'contraindications': ['심장 질환', '고혈압'],
        'precautions': ['심박수 모니터링 필수', '충분한 휴식'],
        'instructions': '''
1. 빠른 물속 달리기 (3분) + 휴식 (1분) x 3세트
2. 물속 버피 (2분) + 휴식 (1분) x 3세트
3. 고강도 팔다리 협응 동작 (3분) + 휴식 (1분) x 2세트
4. 마무리 스트레칭 (5분)
        ''',
        'media': [],
        'rating': 4.8,
      },

      // === 일반 재활 (GENERAL) ===
      {
        'title': '관절 가동범위 운동',
        'description': '어깨, 팔꿈치, 손목 등 상지 관절의 가동범위를 넓힙니다.',
        'type': 'GENERAL',
        'category': ['rom', 'strength'],
        'difficulty_level': 'LEVEL_2',
        'target_goals': ['FUNCTIONAL', 'PHYSICAL'],
        'tags': ['ROM', '관절', '일반재활'],
        'duration_minutes': 20,
        'equipment': ['치료 밴드', '가벼운 아령'],
        'contraindications': ['급성 관절염', '최근 골절'],
        'precautions': ['통증 범위 내에서만 시행', '천천히 진행'],
        'instructions': '''
1. 어깨 회전 운동 (5분)
2. 팔꿈치 굽히고 펴기 (5분)
3. 손목 회전 및 굽히기 (5분)
4. 스트레칭 및 이완 (5분)
        ''',
        'media': [],
        'rating': 4.4,
      },
    ];

    try {
      for (var contentData in sampleContents) {
        await _firestore.collection('contents').add({
          ...contentData,
          'organization_id': null, // 글로벌 콘텐츠
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (kDebugMode) {
        debugPrint('✅ 샘플 콘텐츠 ${sampleContents.length}개 생성 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 샘플 콘텐츠 생성 실패: $e');
      }
      rethrow;
    }
  }

  /// 전체 초기화 실행
  Future<void> initializeAll() async {
    if (kDebugMode) {
      debugPrint('🔄 Firebase 초기 데이터 생성 시작...');
    }

    await createAssessmentTemplate();
    await createSampleContents();

    if (kDebugMode) {
      debugPrint('✅ Firebase 초기화 완료!');
    }
  }
}
