# 파묘 (Pamyo) - 프로젝트 구조

## Phase 1: 기본 메모 CRUD + Firebase 연동 ✅

### 프로젝트 폴더 구조

```
lib/
├── core/                           # 핵심 기능 (공통)
│   ├── config/
│   │   └── firebase_config.dart    # Firebase 초기화 설정
│   ├── constants/
│   │   └── app_constants.dart      # 앱 전역 상수
│   ├── theme/                      # (향후) 테마 설정
│   ├── utils/                      # (향후) 유틸리티 함수
│   └── router/                     # (향후) 라우팅 설정
│
├── features/                       # 기능별 모듈
│   ├── memo/                       # 메모 기능
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── firebase_memo_datasource.dart  # Firestore 데이터 소스
│   │   │   ├── models/
│   │   │   │   └── memo_model.dart                # Firestore 모델
│   │   │   └── repositories/
│   │   │       └── memo_repository_impl.dart      # Repository 구현
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── memo.dart                      # 메모 엔티티
│   │   │   └── repositories/
│   │   │       └── memo_repository.dart           # Repository 인터페이스
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── memo_providers.dart            # Riverpod 프로바이더
│   │       ├── screens/
│   │       │   └── memo_list_screen.dart          # 메모 목록 화면
│   │       └── widgets/                           # (향후) 재사용 위젯
│   │
│   └── auth/                       # (향후) 인증 기능
│       ├── data/
│       └── presentation/
│
├── shared/                         # 공유 위젯/컴포넌트
│   └── widgets/
│
└── main.dart                       # 앱 진입점

```

## 기술 스택

### Frontend (Flutter)
- **State Management**: flutter_riverpod ^2.6.1
- **Navigation**: go_router ^14.6.2 (설치됨, 미구현)
- **Firebase**:
  - firebase_core ^3.8.1
  - firebase_auth ^5.3.4
  - cloud_firestore ^5.5.2
- **Utilities**:
  - intl ^0.19.0
  - uuid ^4.5.1

## 데이터 모델

### Memo Entity
```dart
class Memo {
  final String id;
  final String userId;
  final String title;
  final String content;
  final List<String> tags;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
}
```

### Firestore 컬렉션 구조
- **memos**: 메모 데이터
- **folders**: (향후) 폴더 데이터
- **tags**: (향후) 태그 데이터
- **users**: (향후) 사용자 데이터

## 구현된 기능

### ✅ Phase 1 - 완료
1. **프로젝트 구조 설정**
   - Clean Architecture 패턴 적용
   - Feature-First 폴더 구조

2. **Firebase 연동 준비**
   - Firebase 설정 파일 생성
   - Firestore CRUD 데이터소스 구현

3. **메모 CRUD**
   - 메모 생성 (Create)
   - 메모 목록 조회 (Read)
   - 메모 상세 보기 (Read)
   - 메모 삭제 (Delete)
   - 실시간 업데이트 (Stream)

4. **UI/UX**
   - 메모 목록 화면
   - 메모 생성 다이얼로그
   - 메모 상세 다이얼로그
   - 삭제 확인 다이얼로그

## Firebase 설정 필요

프로젝트를 실행하기 전에 다음 설정이 필요합니다:

### 1. Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. Android/iOS 앱 추가
3. `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 다운로드

### 2. Firebase 설정 파일 업데이트
`lib/core/config/firebase_config.dart` 파일의 Firebase 옵션을 실제 값으로 교체:

```dart
static const FirebaseOptions _androidOptions = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',        // ← 실제 값으로 교체
  appId: 'YOUR_ANDROID_APP_ID',          // ← 실제 값으로 교체
  messagingSenderId: 'YOUR_SENDER_ID',   // ← 실제 값으로 교체
  projectId: 'YOUR_PROJECT_ID',          // ← 실제 값으로 교체
  storageBucket: 'YOUR_STORAGE_BUCKET',  // ← 실제 값으로 교체
);
```

### 3. Android 설정
`android/app/google-services.json` 파일 배치

### 4. iOS 설정
`ios/Runner/GoogleService-Info.plist` 파일 배치

### 5. Firestore 규칙 설정 (개발용)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // 주의: 프로덕션에서는 보안 규칙 필요!
    }
  }
}
```

## 다음 단계 (Phase 2)

### 예정 기능
1. **Firebase Authentication 연동**
   - Google 로그인
   - 이메일/비밀번호 로그인
   - 사용자 프로필 관리

2. **메모 업데이트 (Update) 기능**
   - 메모 편집 화면
   - 인라인 편집

3. **Gemini API 연동**
   - 자동 폴더 분류
   - 자동 태그 생성
   - 메모 제목 자동 생성

4. **폴더/태그 관리**
   - 폴더 CRUD
   - 태그 관리
   - 필터링 기능

## 실행 방법

### 1. 의존성 설치
```bash
flutter pub get
```

### 2. Firebase 설정 완료 확인
- `firebase_config.dart` 업데이트
- `google-services.json` / `GoogleService-Info.plist` 배치

### 3. 앱 실행
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

## 아키텍처 패턴

### Clean Architecture
- **Presentation Layer**: UI, Widgets, Providers
- **Domain Layer**: Entities, Repository Interfaces
- **Data Layer**: Models, Repository Implementations, Data Sources

### 의존성 방향
```
Presentation → Domain ← Data
```

### State Management
- **Riverpod**: 전역 상태 관리
- **StreamProvider**: 실시간 데이터 업데이트
- **FutureProvider**: 비동기 데이터 로딩

## 참고사항

- 현재는 임시 사용자 ID로 개발 중 (Firebase Auth 미연동)
- Phase 2에서 실제 인증 시스템 구현 예정
- 메모 업데이트 기능은 Phase 2에서 구현 예정
