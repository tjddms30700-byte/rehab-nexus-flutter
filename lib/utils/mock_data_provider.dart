import '../models/patient.dart';
import '../models/assessment.dart';
import '../models/content.dart';
import '../constants/assessment_templates_helper.dart';
import '../constants/enums.dart';

/// Mock 데이터 제공 유틸리티
class MockDataProvider {
  /// 테스트용 환자 목록 생성
  static List<Patient> createMockPatients() {
    return [
      Patient(
        id: 'patient_001',
        organizationId: 'org_001',
        patientCode: 'P001',
        name: '홍길동',
        birthDate: DateTime(2016, 3, 15), // 8세
        gender: 'M',
        diagnosis: ['발달지연', '균형장애'],
        assignedTherapistId: 'therapist_001',
        medicalHistory: {
          'notes': '조산아 출생력, 뇌성마비 경증'
        },
        createdAt: DateTime.now(),
      ),
      Patient(
        id: 'patient_002',
        organizationId: 'org_001',
        patientCode: 'P002',
        name: '김영희',
        birthDate: DateTime(2014, 7, 20), // 10세
        gender: 'F',
        diagnosis: ['감각통합장애', '주의력결핍'],
        assignedTherapistId: 'therapist_001',
        medicalHistory: {
          'notes': 'ADHD 진단, 감각통합치료 병행 중'
        },
        createdAt: DateTime.now(),
      ),
      Patient(
        id: 'patient_003',
        organizationId: 'org_001',
        patientCode: 'P003',
        name: '박민수',
        birthDate: DateTime(2018, 1, 10), // 6세
        gender: 'M',
        diagnosis: ['근력저하', '발달지연'],
        assignedTherapistId: 'therapist_001',
        medicalHistory: {
          'notes': '근육긴장도 저하, 대근육 발달 지연'
        },
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// 테스트용 평가 데이터 생성
  static Assessment createMockAssessment({
    required String patientId,
    required String therapistId,
  }) {
    // 샘플 점수 (52점, Level 2)
    final scores = <ItemScore>[
      // 균형 (Balance) - 3개 항목
      ItemScore(itemId: 'balance_01', score: 2), // 서 있는 자세
      ItemScore(itemId: 'balance_02', score: 2), // 보행 시 균형
      ItemScore(itemId: 'balance_03', score: 1), // 한 발 서기
      
      // 호흡 (Breathing) - 2개 항목
      ItemScore(itemId: 'breathing_01', score: 3), // 호흡 조절
      ItemScore(itemId: 'breathing_02', score: 2), // 수중 호흡
      
      // 근력 (Strength) - 3개 항목
      ItemScore(itemId: 'strength_01', score: 2), // 팔 근력
      ItemScore(itemId: 'strength_02', score: 2), // 다리 근력
      ItemScore(itemId: 'strength_03', score: 3), // 몸통 근력
      
      // 감각통합 (Sensory) - 3개 항목
      ItemScore(itemId: 'sensory_01', score: 2), // 촉각 반응
      ItemScore(itemId: 'sensory_02', score: 3), // 수온 적응
      ItemScore(itemId: 'sensory_03', score: 2), // 물 흐름 감각
      
      // 참여도 (Participation) - 2개 항목
      ItemScore(itemId: 'participation_01', score: 4), // 활동 참여
      ItemScore(itemId: 'participation_02', score: 3), // 치료사 협조
      
      // 관절가동범위 (ROM) - 2개 항목
      ItemScore(itemId: 'rom_01', score: 3), // 상지 ROM
      ItemScore(itemId: 'rom_02', score: 2), // 하지 ROM
      
      // 협응력 (Coordination) - 2개 항목
      ItemScore(itemId: 'coordination_01', score: 2), // 양손 협응
      ItemScore(itemId: 'coordination_02', score: 2), // 팔다리 협응
      
      // 수중 특화 (Aquatic Specific) - 2개 항목
      ItemScore(itemId: 'aquatic_01', score: 3), // 물에 대한 두려움
      ItemScore(itemId: 'aquatic_02', score: 2), // 부력 이용
      
      // 안전/적응 (Safety) - 1개 항목
      ItemScore(itemId: 'safety_01', score: 3), // 안전 인식
      
      // 지구력 (Endurance) - 1개 항목
      ItemScore(itemId: 'endurance_01', score: 2), // 활동 지속력
    ];

    final summary = AssessmentSummary(
      strengths: ['활동 참여도 우수', '치료사 협조 양호', '호흡 조절 가능'],
      challenges: ['한 발 서기 어려움', '물속 보행 불안정', '팔다리 협응 미흡'],
      recommendations: [
        '균형 훈련 집중 (Level 1-2 콘텐츠)',
        '호흡 조절 능력 활용한 수중 활동',
        '협응력 개선 위한 단계적 운동',
      ],
    );

    return Assessment(
      id: 'assessment_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      therapistId: therapistId,
      assessmentType: AssessmentType.initial,
      templateId: 'template_aquatic_21items',
      assessmentDate: DateTime.now(),
      scores: scores,
      totalScore: 52, // 총점 52점 = Level 2
      summary: summary,
      createdAt: DateTime.now(),
    );
  }

  /// 테스트용 콘텐츠 목록 생성
  static List<Content> createMockContents() {
    return [
      Content(
        id: 'content_001',
        title: '물속 균형 잡기',
        description: '수중에서 안정적인 자세를 유지하며 균형감각을 향상시키는 기초 운동',
        type: ContentType.aquatic,
        category: ['균형', '자세'],
        difficultyLevel: DifficultyLevel.level2,
        targetGoals: ['PHYSICAL'],
        durationMinutes: 15,
        equipment: ['풀 누들', '부력 보조 장비'],
        instructions: '1. 풀 누들을 양손으로 잡고 물 위에 띄웁니다\n2. 발끝으로 서서 균형을 잡습니다\n3. 10초간 자세를 유지합니다\n4. 3회 반복합니다',
        precautions: ['치료사가 항상 근처에서 보조합니다', '미끄럼 방지 매트를 사용합니다'],
        tags: ['균형', '자세', '기초'],
        rating: 4.5,
        createdAt: DateTime.now(),
      ),
      Content(
        id: 'content_002',
        title: '호흡 조절 기초',
        description: '수중에서 안전하게 호흡을 조절하고 물에 대한 두려움을 감소시키는 훈련',
        type: ContentType.aquatic,
        category: ['호흡', '적응'],
        difficultyLevel: DifficultyLevel.level1,
        targetGoals: ['PHYSICAL'],
        durationMinutes: 10,
        equipment: [],
        instructions: '1. 얕은 물에서 시작합니다\n2. 코로 숨을 들이마시고 입으로 내쉽니다\n3. 물에 입을 담그고 천천히 공기를 내뿜습니다\n4. 5회 반복합니다',
        precautions: ['환자가 불안해하면 즉시 중단합니다', '물 깊이는 가슴 높이를 넘지 않습니다'],
        tags: ['호흡', '적응', '기초'],
        rating: 4.8,
        createdAt: DateTime.now(),
      ),
      Content(
        id: 'content_003',
        title: '팔 움직임 기초',
        description: '수중 저항을 이용하여 팔 근력과 관절 가동범위를 향상시키는 운동',
        type: ContentType.aquatic,
        category: ['근력', '상지'],
        difficultyLevel: DifficultyLevel.level2,
        targetGoals: ['PHYSICAL', 'FUNCTIONAL'],
        durationMinutes: 20,
        equipment: ['수중 덤벨', '부력 보드'],
        instructions: '1. 허리 깊이의 물에 섭니다\n2. 팔을 옆으로 펼쳤다 모읍니다\n3. 10회 반복합니다\n4. 수중 덤벨을 사용하여 저항을 추가합니다',
        precautions: ['어깨에 통증이 있으면 중단합니다', '천천히 움직여 부상을 방지합니다'],
        tags: ['근력', '상지', '저항'],
        rating: 4.3,
        createdAt: DateTime.now(),
      ),
      Content(
        id: 'content_004',
        title: '다리 강화 운동',
        description: '수중에서 다리 근력을 강화하고 보행 능력을 향상시키는 운동',
        type: ContentType.aquatic,
        category: ['근력', '하지', '보행'],
        difficultyLevel: DifficultyLevel.level3,
        targetGoals: ['PHYSICAL', 'FUNCTIONAL'],
        durationMinutes: 25,
        equipment: ['풀 누들', '계단'],
        instructions: '1. 수중 계단을 오르내립니다\n2. 각 다리 10회씩 반복합니다\n3. 풀 누들로 균형을 잡습니다',
        precautions: ['무릎이나 발목에 통증이 있으면 중단합니다'],
        tags: ['근력', '하지', '보행'],
        rating: 4.6,
        createdAt: DateTime.now(),
      ),
      Content(
        id: 'content_005',
        title: '협응 훈련',
        description: '팔과 다리의 협응력을 향상시키는 복합 운동',
        type: ContentType.aquatic,
        category: ['협응', '균형'],
        difficultyLevel: DifficultyLevel.level3,
        targetGoals: ['PHYSICAL', 'COGNITIVE'],
        durationMinutes: 20,
        equipment: ['공', '풀 누들'],
        instructions: '1. 공을 던지고 받기\n2. 다리로 공 차기\n3. 좌우 균형 잡기',
        precautions: ['천천히 진행하며 속도를 조절합니다'],
        tags: ['협응', '균형', '인지'],
        rating: 4.4,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
