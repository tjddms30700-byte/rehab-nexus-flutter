#!/bin/bash

echo "🚀 Rehab Nexus - Firebase Hosting 배포"
echo "========================================"
echo ""

# 프로젝트 디렉토리로 이동
cd /home/user/flutter_app

# Firebase 프로젝트 확인
echo "📋 Firebase 프로젝트: rehab-nexus-korea"
echo ""

# Web 빌드 (이미 되어있지만 최신 버전으로)
echo "🔨 Flutter Web 빌드 중..."
flutter build web --release

if [ $? -eq 0 ]; then
    echo "✅ Web 빌드 완료!"
    echo ""
else
    echo "❌ Web 빌드 실패!"
    exit 1
fi

# 빌드 파일 확인
echo "📦 빌드 파일 확인:"
ls -lh build/web/ | grep -E "(index.html|main.dart.js)"
echo ""

# Firebase 배포
echo "🌐 Firebase Hosting 배포 중..."
echo ""
echo "⚠️  주의: Firebase 로그인이 필요합니다!"
echo "다음 명령어를 실행하세요:"
echo ""
echo "  firebase login"
echo "  firebase deploy --only hosting"
echo ""
echo "배포 완료 후 URL:"
echo "  https://rehab-nexus-korea.web.app"
echo "  https://rehab-nexus-korea.firebaseapp.com"
echo ""
