# Gemini API 설정 가이드

파묘(Pamyo)의 AI 자동 분류 기능을 사용하려면 Gemini API 키가 필요합니다.

## 1. Gemini API 키 발급

1. [Google AI Studio](https://aistudio.google.com/app/apikey)에 접속
2. Google 계정으로 로그인
3. "Create API Key" 버튼 클릭
4. API 키 복사

## 2. API 키 설정

### 방법 1: 환경 변수로 실행 (권장)

```bash
# macOS/Linux
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here

# 또는 빌드 시
flutter build macos --dart-define=GEMINI_API_KEY=your_api_key_here
```

### 방법 2: 코드에 직접 입력 (테스트용만 사용)

`lib/core/config/env_config.dart` 파일을 수정:

```dart
class EnvConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your_api_key_here', // 여기에 API 키 입력
  );

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
}
```

**주의**: 이 방법은 테스트 목적으로만 사용하세요. 실제 배포 시에는 환경 변수를 사용해야 합니다.

## 3. AI 자동 분류 기능

API 키가 설정되면 다음 기능이 자동으로 활성화됩니다:

### 메모 작성 시 자동 분류
- 메모 제목과 내용을 분석하여 적절한 폴더 자동 선택
- 관련 태그 자동 생성 (최대 5개)
- 저장 후 분류 결과를 스낵바로 표시

### 지원되는 AI 기능
1. **폴더 자동 분류**: 메모 내용에 맞는 폴더 추천
2. **태그 자동 생성**: 메모와 관련된 키워드 태그 생성
3. **제목 자동 생성**: 제목이 없을 때 내용 기반으로 제목 생성 (예정)

## 4. API 키 없이 사용

API 키가 없어도 앱은 정상적으로 작동합니다. 단, AI 자동 분류 기능만 비활성화됩니다.

- 메모 작성 가능
- 수동으로 폴더 선택 및 태그 입력
- 기본적인 CRUD 기능 모두 사용 가능

## 5. 비용

Gemini API는 무료 할당량을 제공합니다:
- Gemini 1.5 Flash: 분당 15 요청, 하루 1,500 요청 (무료)

자세한 내용은 [Gemini API 가격 정책](https://ai.google.dev/pricing)을 참조하세요.

## 6. 문제 해결

### API 키가 작동하지 않을 때
1. API 키가 올바르게 입력되었는지 확인
2. Google AI Studio에서 API 키가 활성화되어 있는지 확인
3. 인터넷 연결 상태 확인

### 오류 메시지 확인
앱 로그에서 Gemini API 관련 오류를 확인할 수 있습니다:
```bash
flutter logs
```

## 7. 보안 주의사항

- API 키를 GitHub 등 공개 저장소에 커밋하지 마세요
- `.env` 파일은 `.gitignore`에 포함되어 있습니다
- 프로덕션 배포 시 환경 변수를 사용하세요
