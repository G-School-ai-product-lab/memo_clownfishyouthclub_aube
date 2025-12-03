# 파묘 (Pamyo) - AI 기반 자동 메모 분류 서비스

> **"찾던 것이 나왔다"** - 사용자는 메모만 작성하면 AI가 자동으로 분류하는 완전 자동화 메모 비서

![Flutter](https://img.shields.io/badge/Flutter-3.29.1-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)

## 프로젝트 개요

파묘는 사용자가 메모를 작성하면 AI가 자동으로 폴더/태그를 생성하고 분류해주는 스마트 메모 애플리케이션입니다.

### 핵심 가치
- **완전 자동화**: 메모만 작성하면 AI가 자동으로 분류
- **의미 기반 검색**: 자연어로 메모를 찾을 수 있음
- **링크 지능 분석**: URL 저장 시 자동으로 요약 및 분류

## 기술 스택

### Frontend
- **Flutter** 3.29.1 - 크로스 플랫폼 모바일 앱
- **Riverpod** 2.6.1 - 상태 관리
- **go_router** 14.6.2 - 라우팅

### Backend (예정)
- **Python FastAPI** - RESTful API
- **Google Gemini API** - AI 분류 엔진

### Database
- **Firebase/Firestore** - 메인 데이터베이스 (NoSQL)
- **Supabase PostgreSQL** - 관계형 데이터 (예정)
- **Pinecone** - 벡터 검색 (예정)

### Authentication
- **Firebase Authentication** - 사용자 인증

## 개발 로드맵

### ✅ Phase 1: 기본 메모 CRUD + Firebase 연동 (완료)
- [x] Flutter 프로젝트 구조 설정
- [x] Firebase 연동 준비
- [x] 메모 CRUD 기능 (생성, 읽기, 삭제)
- [x] Firestore 실시간 동기화
- [x] 기본 UI 구현

### 🚧 Phase 2: Gemini API 연동 + 자동 분류 (진행 중)
- [ ] Firebase Authentication 구현
- [ ] 메모 업데이트 (수정) 기능
- [ ] Gemini API 연동
- [ ] 자동 폴더 생성 및 분류
- [ ] 자동 태그 생성
- [ ] FastAPI 백엔드 구축

### 📋 Phase 3: 벡터 검색 + 자연어 검색
- [ ] Pinecone 벡터 DB 연동
- [ ] 임베딩 생성 및 저장
- [ ] 자연어 기반 의미 검색
- [ ] 관련 메모 추천

### 📋 Phase 4: 링크 크롤링 + OCR
- [ ] URL 메타데이터 추출
- [ ] 웹페이지 자동 요약
- [ ] 이미지 OCR 기능
- [ ] 첨부파일 관리

## 시작하기

### 사전 요구사항
- Flutter SDK 3.29.1 이상
- Dart 3.7.0 이상
- Firebase 프로젝트 (설정 필요)
- Android Studio / Xcode (모바일 개발용)

### 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/yourusername/pamyo_one.git
cd pamyo_one
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **Firebase 설정**

자세한 설정은 [FIREBASE_SETUP.md](FIREBASE_SETUP.md)를 참고하세요.

간단 요약:
- Firebase 프로젝트 생성
- `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 추가
- `lib/core/config/firebase_config.dart` 파일 업데이트

4. **앱 실행**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (개발 중)
flutter run -d chrome
```

## 프로젝트 구조

```
lib/
├── core/                    # 핵심 기능
│   ├── config/             # 설정 파일
│   └── constants/          # 상수
├── features/               # 기능별 모듈
│   ├── memo/              # 메모 기능
│   │   ├── data/          # 데이터 레이어
│   │   ├── domain/        # 도메인 레이어
│   │   └── presentation/  # UI 레이어
│   └── auth/              # 인증 기능 (예정)
├── shared/                 # 공유 컴포넌트
└── main.dart              # 앱 진입점
```

자세한 구조는 [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)를 참고하세요.

## 주요 기능

### 현재 구현된 기능 (Phase 1)
- ✅ 메모 작성 및 저장
- ✅ 메모 목록 조회 (실시간)
- ✅ 메모 상세 보기
- ✅ 메모 삭제
- ✅ Firestore 실시간 동기화

### 예정 기능 (Phase 2+)
- 🔜 AI 자동 폴더 분류
- 🔜 AI 자동 태그 생성
- 🔜 자연어 기반 검색
- 🔜 링크 자동 요약
- 🔜 이미지 OCR
- 🔜 메모 공유

## 기여하기

기여는 언제나 환영합니다! 다음 단계를 따라주세요:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

## 문의

프로젝트 관련 문의사항이나 버그 리포트는 [Issues](https://github.com/yourusername/pamyo_one/issues)에 등록해주세요.

## 참고 문서

- [프로젝트 구조 상세](PROJECT_STRUCTURE.md)
- [Firebase 설정 가이드](FIREBASE_SETUP.md)
- [Flutter 공식 문서](https://flutter.dev/docs)
- [Firebase 공식 문서](https://firebase.google.com/docs)
- [Gemini API 문서](https://ai.google.dev/docs)

---

Made with ❤️ by Pamyo Team
