# Firebase 백엔드 연동 가이드

## 📋 개요

AQU LAB Care 앱은 Firebase Firestore를 사용하여 데이터를 영속화합니다.
현재 **Mock 모드**로 동작하며, Firebase 설정 후 실제 데이터베이스를 사용합니다.

---

## 🔧 Firebase 설정 단계

### 1단계: Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **새 프로젝트 생성** 또는 기존 프로젝트 선택
3. Firestore Database 활성화:
   - **Build** → **Firestore Database** 클릭
   - **Create Database** 클릭
   - 보안 규칙: **테스트 모드** 또는 **프로덕션 모드** 선택
   - 위치: **asia-northeast3** (서울) 권장

### 2단계: Android 앱 등록

1. Firebase 프로젝트 설정 → Android 앱 추가
2. **Android 패키지 이름**: `com.rehabnexus.rehab`
3. **google-services.json** 다운로드
4. 다운로드한 파일을 `/opt/flutter/google-services.json`에 업로드

### 3단계: Web 앱 등록

1. Firebase 프로젝트 설정 → Web 앱 추가
2. Firebase Configuration 정보 복사
3. `lib/firebase_options.dart` 파일 생성 (자동 생성 예정)

### 4단계: Flutter 앱에서 Firebase 초기화

`lib/main.dart` 파일의 주석 해제:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

---

## 📊 Firestore 데이터베이스 구조

### 1. Organizations (조직)

**Collection**: `organizations`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 조직 ID (자동 생성) |
| name | string | 조직명 |
| type | string | 조직 유형 (REHAB_CENTER, HOSPITAL) |
| address | string | 주소 |
| phone | string | 전화번호 |
| created_at | timestamp | 생성일시 |

### 2. Users (사용자)

**Collection**: `users`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 사용자 ID (자동 생성) |
| organization_id | string | 조직 ID |
| name | string | 이름 |
| email | string | 이메일 |
| role | string | 역할 (THERAPIST, GUARDIAN, ADMIN) |
| phone | string | 전화번호 |
| created_at | timestamp | 생성일시 |

### 3. Patients (환자)

**Collection**: `patients`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 환자 ID (자동 생성) |
| organization_id | string | 조직 ID |
| patient_code | string | 환자 코드 |
| name | string | 이름 |
| birth_date | timestamp | 생년월일 |
| age | int | 나이 (자동 계산) |
| gender | string | 성별 (M, F) |
| diagnosis | array<string> | 진단명 목록 |
| assigned_therapist_id | string | 담당 치료사 ID |
| guardian_ids | array<string> | 보호자 ID 목록 |
| status | string | 상태 (ACTIVE, INACTIVE, DISCHARGED) |
| medical_history | map | 의료 기록 |
| created_at | timestamp | 생성일시 |

**인덱스 (필수)**:
- `organization_id` (ASC) + `status` (ASC) + `created_at` (DESC)
- `assigned_therapist_id` (ASC) + `status` (ASC) + `created_at` (DESC)
- `guardian_ids` (ARRAY) + `status` (ASC)

### 4. Assessments (평가)

**Collection**: `assessments`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 평가 ID (자동 생성) |
| patient_id | string | 환자 ID |
| therapist_id | string | 평가자 ID |
| assessment_type | string | 평가 유형 (INITIAL, REASSESSMENT, DISCHARGE) |
| template_id | string | 템플릿 ID |
| assessment_date | timestamp | 평가 일시 |
| scores | map | 항목별 점수 (key: 항목ID, value: 점수) |
| total_score | int | 총점 |
| percentage | double | 백분율 |
| level | string | 레벨 (Level 1-5) |
| summary | map | 요약 (strengths, challenges, recommendations) |
| created_at | timestamp | 생성일시 |

**인덱스 (필수)**:
- `patient_id` (ASC) + `assessment_date` (DESC)
- `therapist_id` (ASC) + `assessment_date` (DESC)

### 5. Goals (목표)

**Collection**: `goals`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 목표 ID (자동 생성) |
| patient_id | string | 환자 ID |
| therapist_id | string | 치료사 ID |
| assessment_id | string? | 연관 평가 ID (선택) |
| goal_text | string | 목표 내용 |
| smart_criteria | map | SMART 기준 |
| category | string | 카테고리 (FUNCTIONAL, PHYSICAL, SOCIAL, COGNITIVE) |
| priority | string | 우선순위 (HIGH, MEDIUM, LOW) |
| target_date | timestamp | 목표 기한 |
| status | string | 상태 (IN_PROGRESS, ACHIEVED, REVISED, CANCELLED) |
| progress_percentage | double | 진행률 (0-100) |
| created_at | timestamp | 생성일시 |

**인덱스 (필수)**:
- `patient_id` (ASC) + `status` (ASC) + `created_at` (DESC)
- `therapist_id` (ASC) + `status` (ASC)

### 6. Contents (콘텐츠)

**Collection**: `contents`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 콘텐츠 ID (자동 생성) |
| organization_id | string? | 조직 ID (null이면 전역) |
| title | string | 제목 |
| description | string | 설명 |
| type | string | 유형 (AQUATIC, GENERAL, OT, PT) |
| category | array<string> | 카테고리 목록 |
| difficulty_level | string | 난이도 (LEVEL_1 ~ LEVEL_5) |
| target_goals | array<string> | 목표 태그 |
| tags | array<string> | 태그 |
| duration_minutes | int | 소요 시간 (분) |
| equipment | array<string> | 필요 장비 |
| contraindications | array<string> | 금기사항 |
| precautions | array<string> | 주의사항 |
| instructions | string | 수행 방법 |
| media | array<map> | 미디어 (이미지, 영상) |
| rating | double | 평점 (0-5) |
| created_at | timestamp | 생성일시 |

**인덱스 (필수)**:
- `organization_id` (ASC) + `type` (ASC) + `difficulty_level` (ASC)
- `type` (ASC) + `difficulty_level` (ASC)

### 7. Sessions (세션 기록)

**Collection**: `sessions`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 세션 ID (자동 생성) |
| patient_id | string | 환자 ID |
| therapist_id | string | 치료사 ID |
| session_date | timestamp | 세션 일시 |
| content_ids | array<string> | 사용한 콘텐츠 ID 목록 |
| duration_minutes | int | 세션 시간 (분) |
| patient_response | string | 환자 반응 (POSITIVE, NEUTRAL, NEGATIVE) |
| cooperation_level | string | 협조 수준 (EXCELLENT, GOOD, FAIR, POOR) |
| fatigue_level | string | 피로도 (LOW, MEDIUM, HIGH) |
| special_notes | string | 특이사항 |
| internal_notes | string | 내부 메모 (보호자 비공개) |
| created_at | timestamp | 생성일시 |

**인덱스 (필수)**:
- `patient_id` (ASC) + `session_date` (DESC)
- `therapist_id` (ASC) + `session_date` (DESC)

### 8. HomePrograms (홈프로그램)

**Collection**: `home_programs`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 프로그램 ID (자동 생성) |
| patient_id | string | 환자 ID |
| therapist_id | string | 치료사 ID |
| guardian_id | string | 보호자 ID |
| task_title | string | 과제 제목 |
| task_description | string | 과제 설명 |
| frequency | string | 빈도 |
| assigned_date | timestamp | 배정 일시 |
| due_date | timestamp | 마감 일시 |
| status | string | 상태 (ACTIVE, COMPLETED) |
| completion_date | timestamp? | 완료 일시 |
| guardian_notes | string | 보호자 코멘트 |
| difficulty | string | 난이도 (EASY, MODERATE, HARD) |
| created_at | timestamp | 생성일시 |

**인덱스 (필수)**:
- `patient_id` (ASC) + `status` (ASC) + `assigned_date` (DESC)
- `guardian_id` (ASC) + `status` (ASC)

---

## 🔒 Firestore 보안 규칙

### 개발 모드 (테스트용)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 모든 읽기/쓰기 허용 (개발 전용)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 프로덕션 모드 (배포용)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 인증된 사용자만 접근
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // 환자 데이터: 조직 내 치료사만 접근
    match /patients/{patientId} {
      allow read: if request.auth != null 
        && (request.auth.token.role == 'THERAPIST' || request.auth.token.role == 'GUARDIAN');
      allow write: if request.auth != null 
        && request.auth.token.role == 'THERAPIST';
    }
    
    // 평가 데이터: 담당 치료사만 작성
    match /assessments/{assessmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.auth.token.role == 'THERAPIST';
    }
    
    // 세션 기록: 치료사만 작성
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.auth.token.role == 'THERAPIST';
    }
    
    // 목표: 치료사만 작성
    match /goals/{goalId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.auth.token.role == 'THERAPIST';
    }
    
    // 홈프로그램: 치료사 작성, 보호자 읽기/업데이트
    match /home_programs/{programId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.auth.token.role == 'THERAPIST';
      allow update: if request.auth != null 
        && (request.auth.token.role == 'THERAPIST' || request.auth.token.role == 'GUARDIAN');
    }
  }
}
```

---

## 🚀 서비스 레이어 사용 예시

### 환자 등록

```dart
import 'package:aqu_lab_care/services/patient_service.dart';
import 'package:aqu_lab_care/models/patient.dart';

final patientService = PatientService();

// 환자 생성
final patient = Patient(
  id: 'temp_id',
  organizationId: 'org_001',
  patientCode: 'P001',
  name: '홍길동',
  birthDate: DateTime(2016, 3, 15),
  gender: 'M',
  diagnosis: ['발달지연', '균형장애'],
  assignedTherapistId: 'therapist_001',
  createdAt: DateTime.now(),
);

// Firestore에 저장
final patientId = await patientService.createPatient(patient);
print('환자 등록 완료: $patientId');
```

### 환자 목록 조회

```dart
// 치료사별 환자 목록
final patients = await patientService.getPatientsByTherapist('therapist_001');

// 실시간 감시 (Stream)
patientService.watchPatientsByTherapist('therapist_001').listen((patients) {
  print('환자 목록 업데이트: ${patients.length}명');
});
```

### 평가 저장

```dart
import 'package:aqu_lab_care/services/assessment_service.dart';
import 'package:aqu_lab_care/models/assessment.dart';

final assessmentService = AssessmentService();

// 평가 생성
final assessment = Assessment(
  id: 'temp_id',
  patientId: 'patient_001',
  therapistId: 'therapist_001',
  assessmentType: AssessmentType.initial,
  templateId: 'template_aquatic_21items',
  assessmentDate: DateTime.now(),
  scores: {
    'balance_01': 3.0,
    'breathing_01': 4.0,
    // ...
  },
  totalScore: 58,
  percentage: 55.2,
  level: 'Level 3',
  summary: {
    'strengths': ['균형 감각 우수', '호흡 조절 양호'],
    'challenges': ['팔다리 협응 부족'],
    'recommendations': ['협응력 강화 운동'],
  },
  createdAt: DateTime.now(),
);

// Firestore에 저장
final assessmentId = await assessmentService.createAssessment(assessment);
print('평가 저장 완료: $assessmentId');
```

### 목표 관리

```dart
import 'package:aqu_lab_care/services/goal_service.dart';
import 'package:aqu_lab_care/models/goal.dart';

final goalService = GoalService();

// 목표 생성
final goal = Goal(
  id: 'temp_id',
  patientId: 'patient_001',
  therapistId: 'therapist_001',
  goalText: '독립적으로 10m 걷기',
  smartCriteria: SmartCriteria(
    specific: '보조 없이 10m 직선 보행',
    measurable: '3회 연속 성공',
    achievable: '현재 3m 가능, 4주 내 달성 가능',
    relevant: '일상생활 독립성 향상',
    timeBound: DateTime.now().add(Duration(days: 28)),
  ),
  category: GoalCategory.functional,
  priority: GoalPriority.high,
  targetDate: DateTime.now().add(Duration(days: 28)),
  status: GoalStatus.inProgress,
  progressPercentage: 0.0,
  createdAt: DateTime.now(),
);

// Firestore에 저장
final goalId = await goalService.createGoal(goal);
print('목표 생성 완료: $goalId');

// 진행률 업데이트
await goalService.updateGoalProgress(goalId, 45.0);
```

---

## 📈 현재 구현 상태

### ✅ 완료된 부분

1. **데이터 모델** (8개)
   - Patient, Assessment, Goal, Content, Session, HomeProgram 등
   - Firestore 직렬화/역직렬화 구현
   - Enum 변환 로직 완성

2. **서비스 레이어** (7개)
   - PatientService, AssessmentService, GoalService
   - ContentService, SessionService, AuthService
   - CRUD 및 Stream 조회 구현

3. **UI 화면** (8개)
   - 환자 등록, 평가 입력, 콘텐츠 추천, 세션 기록
   - 목표 관리, 성과추이 대시보드
   - 보호자 리포트, 보호자 홈프로그램

4. **Mock 데이터**
   - 개발/테스트용 샘플 데이터 생성
   - Firebase 없이도 UI 테스트 가능

### ⏳ 남은 작업

1. **Firebase 초기화**
   - `google-services.json` 설정
   - `firebase_options.dart` 생성
   - `main.dart`에서 Firebase 초기화 활성화

2. **보안 규칙 설정**
   - Firestore 보안 규칙 배포
   - 역할 기반 접근 제어 (RBAC)

3. **인덱스 생성**
   - 복합 쿼리용 인덱스 설정
   - Firebase Console에서 수동 생성 또는 자동 생성

4. **PDF 리포트**
   - 주간/월간 템플릿 완전 구현
   - Firebase Storage 연동

5. **통합 테스트**
   - 실제 데이터로 엔드투엔드 테스트
   - 권한 및 데이터 무결성 검증

---

## 🔍 트러블슈팅

### Firebase 초기화 오류

**증상**: `No Firebase App '[DEFAULT]' has been created`

**해결 방법**:
1. `google-services.json` 파일 확인
2. `firebase_options.dart` 파일 생성
3. `main.dart`에서 `Firebase.initializeApp()` 주석 해제

### 인덱스 오류

**증상**: `The query requires an index`

**해결 방법**:
1. 에러 메시지에 포함된 링크 클릭
2. Firebase Console에서 자동으로 인덱스 생성
3. 또는 위의 "Firestore 데이터베이스 구조" 섹션 참조

### 보안 규칙 오류

**증상**: `PERMISSION_DENIED: Missing or insufficient permissions`

**해결 방법**:
1. Firestore 보안 규칙을 개발 모드로 변경 (테스트용)
2. Firebase 인증 토큰에 `role` 필드 추가
3. 프로덕션 배포 시 보안 규칙 재설정

---

## 📚 참고 자료

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [Flutter Firebase 플러그인](https://firebase.flutter.dev/)
- [Firestore 데이터 모델링 가이드](https://firebase.google.com/docs/firestore/data-model)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)

---

**마지막 업데이트**: 2025년 1월
**작성자**: AQU LAB Care 개발팀
