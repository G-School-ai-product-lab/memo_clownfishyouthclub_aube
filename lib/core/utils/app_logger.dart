import 'package:logger/logger.dart';

/// 앱 전체에서 사용되는 중앙 집중식 로거
///
/// 사용법:
/// ```dart
/// AppLogger.d('Debug message');
/// AppLogger.i('Info message');
/// AppLogger.w('Warning message');
/// AppLogger.e('Error message', error: e, stackTrace: stack);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    filter: _CustomFilter(),
    printer: PrettyPrinter(
      methodCount: 2, // 스택 트레이스에 표시할 메서드 수
      errorMethodCount: 8, // 에러 발생 시 스택 트레이스에 표시할 메서드 수
      lineLength: 120, // 로그 라인의 최대 길이
      colors: true, // 콘솔에 색상 표시
      printEmojis: true, // 이모지 표시
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: _CustomOutput(),
  );

  /// Debug 레벨 로그 (개발 중에만 표시)
  static void d(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info 레벨 로그 (중요한 정보)
  static void i(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 레벨 로그 (주의가 필요한 상황)
  static void w(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 레벨 로그 (에러 발생)
  static void e(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 레벨 로그 (치명적인 에러)
  static void f(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// 커스텀 필터: 프로덕션 환경에서는 debug 로그를 필터링
class _CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // 프로덕션 환경에서는 Debug 레벨 로그를 표시하지 않음
    const bool isProduction = bool.fromEnvironment('dart.vm.product');

    if (isProduction && event.level == Level.debug) {
      return false;
    }

    return true;
  }
}

/// 커스텀 출력: 콘솔에 로그 출력
class _CustomOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // ignore: avoid_print
      print(line);
    }
  }
}
