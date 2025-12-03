# Firebase 설정 가이드

파묘 앱을 실행하기 위한 Firebase 설정 단계별 가이드입니다.

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력: `pamyo` (또는 원하는 이름)
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

## 2. Firestore Database 설정

1. Firebase Console에서 "Firestore Database" 선택
2. "데이터베이스 만들기" 클릭
3. 보안 규칙 선택:
   - **개발 중**: "테스트 모드에서 시작" 선택
   - **프로덕션**: "프로덕션 모드에서 시작" 선택 후 규칙 수정

4. Firestore 위치 선택 (권장: `asia-northeast3` - 서울)

### 개발용 보안 규칙 (임시)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 프로덕션용 보안 규칙 (권장)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자별 메모 접근 제어
    match /memos/{memoId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }

    // 사용자 프로필
    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    // 폴더 및 태그
    match /folders/{folderId} {
      allow read, write: if request.auth != null;
    }

    match /tags/{tagId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 3. Firebase Authentication 설정

1. Firebase Console에서 "Authentication" 선택
2. "시작하기" 클릭
3. 로그인 방법 설정:

### Google 로그인 활성화
- "Google" 선택
- 사용 설정 ON
- 프로젝트 지원 이메일 선택
- 저장

### 이메일/비밀번호 로그인 활성화
- "이메일/비밀번호" 선택
- 사용 설정 ON
- 저장

## 4. Android 앱 설정

### 4.1 Firebase에 Android 앱 추가
1. Firebase Console 프로젝트 개요에서 "Android 앱 추가" 클릭
2. Android 패키지 이름 입력: `com.pamyo.one` (또는 원하는 패키지명)
3. 앱 닉네임: `파묘` (선택사항)
4. SHA-1 인증서 지문 추가 (선택사항, Google 로그인 시 필요)

### 4.2 google-services.json 다운로드
1. `google-services.json` 파일 다운로드
2. 다음 위치에 파일 배치:
   ```
   android/app/google-services.json
   ```

### 4.3 Android build.gradle 설정

`android/build.gradle` (프로젝트 수준):
```gradle
buildscript {
    dependencies {
        // Firebase
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

`android/app/build.gradle` (앱 수준):
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // 이 줄 추가
}

android {
    defaultConfig {
        applicationId "com.pamyo.one"  // 패키지명 확인
        minSdkVersion 21  // Firebase 최소 요구사항
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true  // 필요한 경우
    }
}
```

### 4.4 SHA-1 인증서 지문 얻기 (Google 로그인용)
```bash
# Debug 키스토어
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release 키스토어 (프로덕션)
keytool -list -v -keystore /path/to/your/keystore.jks
```

## 5. iOS 앱 설정

### 5.1 Firebase에 iOS 앱 추가
1. Firebase Console 프로젝트 개요에서 "iOS 앱 추가" 클릭
2. iOS 번들 ID 입력: `com.pamyo.one` (또는 원하는 번들 ID)
3. 앱 닉네임: `파묘` (선택사항)
4. App Store ID: (선택사항)

### 5.2 GoogleService-Info.plist 다운로드
1. `GoogleService-Info.plist` 파일 다운로드
2. Xcode에서 다음 위치에 파일 추가:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

### 5.3 iOS 번들 ID 설정
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. Runner 프로젝트 선택
3. General → Identity → Bundle Identifier를 `com.pamyo.one`으로 설정

### 5.4 iOS 최소 버전 설정
`ios/Podfile`:
```ruby
platform :ios, '12.0'  # Firebase 최소 요구사항
```

## 6. Flutter 앱 설정

### 6.1 Firebase 설정 파일 업데이트

`lib/core/config/firebase_config.dart` 파일을 다음과 같이 업데이트:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: _getFirebaseOptions(),
    );
  }

  static FirebaseOptions _getFirebaseOptions() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosOptions;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidOptions;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // google-services.json 또는 GoogleService-Info.plist에서 복사
  static const FirebaseOptions _androidOptions = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',              // ← 교체
    appId: 'YOUR_ANDROID_APP_ID',                // ← 교체
    messagingSenderId: 'YOUR_SENDER_ID',         // ← 교체
    projectId: 'YOUR_PROJECT_ID',                // ← 교체
    storageBucket: 'YOUR_STORAGE_BUCKET',        // ← 교체
  );

  static const FirebaseOptions _iosOptions = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',                  // ← 교체
    appId: 'YOUR_IOS_APP_ID',                    // ← 교체
    messagingSenderId: 'YOUR_SENDER_ID',         // ← 교체
    projectId: 'YOUR_PROJECT_ID',                // ← 교체
    storageBucket: 'YOUR_STORAGE_BUCKET',        // ← 교체
    iosBundleId: 'com.pamyo.one',
  );
}
```

### 6.2 Firebase 옵션 값 찾기

#### google-services.json (Android)
```json
{
  "project_info": {
    "project_id": "YOUR_PROJECT_ID",           // ← projectId
    "storage_bucket": "YOUR_STORAGE_BUCKET"    // ← storageBucket
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_ANDROID_APP_ID"  // ← appId
      },
      "api_key": [
        {
          "current_key": "YOUR_ANDROID_API_KEY"    // ← apiKey
        }
      ]
    }
  ],
  "configuration_version": "1"
}
```

#### GoogleService-Info.plist (iOS)
```xml
<key>API_KEY</key>
<string>YOUR_IOS_API_KEY</string>          <!-- apiKey -->
<key>GOOGLE_APP_ID</key>
<string>YOUR_IOS_APP_ID</string>           <!-- appId -->
<key>GCM_SENDER_ID</key>
<string>YOUR_SENDER_ID</string>            <!-- messagingSenderId -->
<key>PROJECT_ID</key>
<string>YOUR_PROJECT_ID</string>           <!-- projectId -->
<key>STORAGE_BUCKET</key>
<string>YOUR_STORAGE_BUCKET</string>       <!-- storageBucket -->
```

## 7. 테스트 사용자 설정 (임시)

개발 중 Firebase Auth 없이 테스트하려면:

`lib/features/memo/presentation/providers/memo_providers.dart`:
```dart
final currentUserIdProvider = Provider<String?>((ref) {
  // 임시 테스트 사용자 ID
  return 'test_user_123';

  // Firebase Auth 연동 후:
  // return FirebaseAuth.instance.currentUser?.uid;
});
```

## 8. 빌드 및 실행

### Android
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### iOS
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## 문제 해결

### Android 빌드 오류

**문제**: `google-services.json` 파일을 찾을 수 없음
```
해결: android/app/google-services.json 위치 확인
```

**문제**: Multidex 오류
```
해결: android/app/build.gradle에 multiDexEnabled true 추가
```

### iOS 빌드 오류

**문제**: CocoaPods 관련 오류
```bash
cd ios
pod deintegrate
pod install
cd ..
```

**문제**: `GoogleService-Info.plist` 파일을 찾을 수 없음
```
해결: Xcode에서 Runner에 파일 직접 추가
```

### Firestore 권한 오류

**문제**: PERMISSION_DENIED 오류
```
해결: Firestore 보안 규칙 확인 및 테스트 모드 활성화
```

## 다음 단계

Firebase 설정 완료 후:
1. 앱 실행 테스트
2. 메모 CRUD 기능 테스트
3. Firestore Console에서 데이터 확인
4. Phase 2: Authentication 구현 시작

## 참고 문서

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 공식 문서](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
