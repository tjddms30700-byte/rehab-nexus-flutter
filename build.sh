#!/bin/bash
set -e

echo "🔧 Installing Flutter SDK..."

# Flutter SDK 다운로드 및 설치
if [ ! -d "$HOME/flutter" ]; then
  echo "📦 Downloading Flutter SDK (stable channel)..."
  cd $HOME
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "✅ Flutter SDK already installed"
fi

# Flutter SDK 경로 추가
export PATH="$HOME/flutter/bin:$PATH"

# Flutter 버전 확인
echo "📋 Flutter version:"
flutter --version

# Flutter 설정
echo "🔧 Configuring Flutter..."
flutter config --enable-web
flutter doctor -v

# 의존성 설치
echo "📦 Installing dependencies..."
flutter pub get

# Web 빌드
echo "🚀 Building Flutter web app..."
flutter build web --release

echo "✅ Build completed successfully!"
