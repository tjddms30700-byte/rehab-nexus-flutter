# 🏥 Rehab Nexus

재활치료 센터를 위한 종합 관리 시스템

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Seoul%20Region-FFCA28?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)

## ✨ 주요 기능

### 🩺 운영 관리 모듈 (8개)
- ✅ **일정 관리**: 예약/출석/보강권 발급
- ✅ **보강권 조회**: 취소/이월/보강 관리
- ✅ **이용자 관리**: 환자 목록
- ✅ **공지사항**: 센터 공지
- ✅ **자료실**: 문서 관리
- ✅ **바우처 관리**: 바우처 현황
- ✅ **수납 관리**: 수납/정산/통계
- ✅ **Firebase 연동**: 실시간 데이터 동기화

### 👨‍⚕️ 임상 기능 모듈 (6개)
- ✅ **환자 등록**: 신규 환자 정보 입력
- ✅ **평가 입력**: 치료 평가 기록
- ✅ **콘텐츠 추천**: AI 기반 콘텐츠 추천
- ✅ **세션 기록**: 치료 세션 관리
- ✅ **목표 관리**: SMART Goal 설정
- ✅ **성과추이**: Dashboard 시각화

### 👪 보호자 모듈 (4개)
- ✅ **예약 관리**: 치료 예약 신청
- ✅ **문의하기**: 센터 문의
- ✅ **치료 리포트**: 치료 진행 현황
- ✅ **홈프로그램**: 가정 치료 프로그램

## 🛠 기술 스택

### Frontend
- **Framework**: Flutter 3.35.4
- **Language**: Dart 3.9.2
- **UI**: Material Design 3
- **State Management**: Provider 6.1.5+1
- **Charts**: fl_chart 0.69.2

### Backend
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Region**: asia-northeast3 (Seoul)

### Local Storage
- **Key-Value**: shared_preferences 2.5.3
- **Document DB**: Hive 2.2.3 + hive_flutter 1.1.0

## 🚀 시작하기

### 사전 요구사항
- Flutter SDK 3.35.4
- Dart SDK 3.9.2
- Android Studio (Android 개발용)
- Xcode (iOS 개발용, macOS만)
- Firebase 프로젝트

### 설치

```bash
# 저장소 클론
git clone https://github.com/tjddms30700-byte/rehab-nexus-flutter.git
cd rehab-nexus-flutter

# 의존성 설치
flutter pub get

# Web 실행
flutter run -d chrome

# Android 실행 (에뮬레이터 또는 실제 기기)
flutter run

# iOS 실행 (macOS만)
flutter run -d ios
```

### Firebase 설정

1. **Firebase Console에서 프로젝트 생성**
   - https://console.firebase.google.com/

2. **Android 앱 추가**
   - 패키지 이름: `com.rehabnexus.rehab`
   - `google-services.json` 다운로드 → `android/app/` 에 배치

3. **Firestore Database 생성**
   - 위치: `asia-northeast3 (Seoul)`
   - 보안 규칙: 테스트 모드로 시작

4. **Authentication 설정**
   - Sign-in method: 이메일/비밀번호 활성화

## 📱 빌드

### Web
```bash
flutter build web --release
```

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🎨 앱 아이콘

앱 아이콘은 다음 위치에 배치되어 있습니다:
- **Android**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **Web**: `web/icons/Icon-*.png`, `web/favicon.png`

## 🔥 Firebase 구성

### 프로젝트 정보
- **프로젝트 ID**: rehab-nexus-korea
- **프로젝트 번호**: 79236393316
- **리전**: asia-northeast3 (Seoul)
- **Storage Bucket**: rehab-nexus-korea.firebasestorage.app

### Firestore 컬렉션
- `patients`: 환자 정보
- `appointments`: 예약 정보
- `attendances`: 출석 기록
- `makeup_tickets`: 보강권 정보
- `vouchers`: 바우처 정보
- `payments`: 수납 정보
- `inquiries`: 문의 사항

## 📂 프로젝트 구조

```
flutter_app/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── firebase_options.dart        # Firebase 설정
│   ├── constants/                   # 상수 정의
│   │   ├── app_theme.dart
│   │   └── enums.dart
│   ├── models/                      # 데이터 모델
│   │   ├── user.dart
│   │   ├── patient.dart
│   │   ├── appointment.dart
│   │   └── ...
│   ├── providers/                   # 상태 관리
│   │   └── app_state.dart
│   ├── screens/                     # 화면 구성
│   │   ├── login_screen.dart
│   │   ├── therapist_home_screen.dart
│   │   ├── guardian_home_screen.dart
│   │   └── ...
│   ├── services/                    # Firebase 서비스
│   │   ├── firestore_service.dart
│   │   ├── appointment_service.dart
│   │   └── ...
│   └── widgets/                     # 공통 위젯
│       └── common_widgets.dart
├── android/                         # Android 설정
├── ios/                             # iOS 설정
├── web/                             # Web 설정
├── pubspec.yaml                     # 의존성 관리
└── README.md                        # 프로젝트 문서
```

## 🧪 테스트

### 테스트 계정
- **치료사**: `therapist@aqualab.com` / `password`
- **보호자**: `guardian@aqualab.com` / `password`

### 테스트 실행
```bash
# 유닛 테스트
flutter test

# 위젯 테스트
flutter test test/widget_test.dart

# 통합 테스트
flutter test integration_test/
```

## 📸 스크린샷

### 치료사 모드
- 일정 관리: 예약 확인 및 출석 체크
- 환자 관리: 환자 목록 조회
- 보강권 조회: 발급/사용/만료 관리

### 보호자 모드
- 예약 신청: 치료 일정 예약
- 문의하기: 센터에 문의 등록
- 치료 리포트: 치료 진행 상황 확인

## 🤝 기여

기여를 환영합니다! Pull Request를 보내주세요.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

MIT License

Copyright (c) 2026 Rehab Nexus

## 👥 저자

- **GitHub**: [@tjddms30700-byte](https://github.com/tjddms30700-byte)

## 🙏 감사의 말

- [Flutter](https://flutter.dev) - 크로스 플랫폼 프레임워크
- [Firebase](https://firebase.google.com) - 백엔드 서비스
- [Material Design](https://m3.material.io) - UI 디자인 시스템

## 📞 문의

프로젝트에 대한 질문이나 제안이 있으시면 Issue를 생성해 주세요.

---

Made with ❤️ by tjddms30700-byte
