/// 환경 변수 설정 클래스
class EnvConfig {
  /// Gemini API Key
  /// 실제 사용 시 환경 변수나 secure storage에서 로드해야 함
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // 기본값은 빈 문자열
  );

  /// API 키가 설정되어 있는지 확인
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
}
