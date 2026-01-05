#!/bin/bash

# iOS Firebase App Distribution 배포 스크립트

set -e  # 에러 발생시 중단

echo "🚀 파묘 iOS 앱 배포 시작..."

# 환경 변수 확인
if [ -z "$FIREBASE_IOS_APP_ID" ]; then
    echo "❌ FIREBASE_IOS_APP_ID 환경 변수가 설정되지 않았습니다."
    echo "사용법: export FIREBASE_IOS_APP_ID='1:395596167392:ios:YOUR_APP_ID'"
    exit 1
fi

# 버전 정보 가져오기
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
echo "📦 버전: $VERSION"

# Flutter 클린 및 의존성 설치
echo "🧹 프로젝트 클린..."
flutter clean
flutter pub get

# CocoaPods 설치
echo "📦 CocoaPods 의존성 설치..."
cd ios
pod install
cd ..

# iOS 빌드
echo "🔨 iOS 빌드 중..."
flutter build ipa --release

# IPA 파일 확인
IPA_PATH="build/ios/ipa/*.ipa"
if [ ! -f $IPA_PATH ]; then
    echo "❌ IPA 파일을 찾을 수 없습니다: $IPA_PATH"
    exit 1
fi

echo "✅ 빌드 완료: $IPA_PATH"

# Release notes 생성
RELEASE_NOTES="파묘 v$VERSION 배포

빌드 날짜: $(date '+%Y-%m-%d %H:%M')

변경 사항:
- 최신 기능 및 버그 수정

테스트 부탁드립니다! 🙏"

# Firebase App Distribution에 배포
echo "📤 Firebase App Distribution에 업로드 중..."
firebase appdistribution:distribute \
  $IPA_PATH \
  --app "$FIREBASE_IOS_APP_ID" \
  --groups "친구들" \
  --release-notes "$RELEASE_NOTES"

echo "✅ 배포 완료! 🎉"
echo "📱 테스터들이 Firebase App Distribution 앱에서 다운로드할 수 있습니다."
