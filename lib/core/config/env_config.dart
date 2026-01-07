/// 환경 변수 설정 클래스
class EnvConfig {
  /// Groq API Key
  /// 실제 사용 시 환경 변수나 secure storage에서 로드해야 함
  /// 사용 방법: flutter run --dart-define=GROQ_API_KEY=your_key_here
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_GROQ_API_KEY_HERE',
  );

  /// API 키가 설정되어 있는지 확인
  static bool get hasGroqApiKey => groqApiKey.isNotEmpty && groqApiKey != 'YOUR_GROQ_API_KEY_HERE';

  /// 레거시 Gemini 호환성을 위한 getter
  @Deprecated('Use groqApiKey instead')
  static String get geminiApiKey => groqApiKey;

  @Deprecated('Use hasGroqApiKey instead')
  static bool get hasGeminiApiKey => hasGroqApiKey;
}
