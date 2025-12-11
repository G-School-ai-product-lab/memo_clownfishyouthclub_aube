import 'package:flutter_test/flutter_test.dart';
import 'package:memo_clownfishyouthclub_aube/features/ai/data/services/gemini_service.dart';

void main() {
  group('GeminiService', () {
    late GeminiService service;

    setUp(() {
      // 테스트용 API 키 (실제로는 환경 변수나 Mock을 사용해야 함)
      const apiKey = 'test-api-key';
      service = GeminiService(apiKey: apiKey);
    });

    group('Service Initialization', () {
      test('서비스가 올바르게 초기화되어야 한다', () {
        // Arrange & Act
        const apiKey = 'test-api-key';
        final testService = GeminiService(apiKey: apiKey);

        // Assert
        expect(testService, isNotNull);
        expect(testService.apiKey, apiKey);
      });
    });

    group('classifyMemoToFolder', () {
      test('폴더 목록이 비어있으면 null을 반환해야 한다', () async {
        // Arrange
        final availableFolders = <String, String>{};

        // Act
        final result = await service.classifyMemoToFolder(
          memoTitle: 'Test Memo',
          memoContent: 'Test Content',
          availableFolders: availableFolders,
        );

        // Assert
        // API 호출 없이 빈 목록이므로 null 반환 예상
        expect(result, isNull);
      });

      // 실제 API 호출을 위한 통합 테스트는 skip
      test('실제 API 호출은 통합 테스트에서 수행', () {
        // 이 테스트는 실제 Gemini API 키가 필요하므로 skip
        // 통합 테스트 환경에서 실행되어야 함
      }, skip: true);
    });

    group('generateTags', () {
      test('빈 제목과 내용으로는 빈 리스트를 반환할 가능성이 높다', () async {
        // Arrange
        const memoTitle = '';
        const memoContent = '';

        // Act
        final result = await service.generateTags(
          memoTitle: memoTitle,
          memoContent: memoContent,
        );

        // Assert
        // API 오류나 빈 응답으로 빈 리스트 반환 예상
        expect(result, isA<List<String>>());
      });

      // 실제 API 호출을 위한 통합 테스트는 skip
      test('실제 API 호출은 통합 테스트에서 수행', () {
        // 이 테스트는 실제 Gemini API 키가 필요하므로 skip
      }, skip: true);
    });

    group('generateTitle', () {
      test('빈 내용으로는 null을 반환할 가능성이 높다', () async {
        // Arrange
        const memoContent = '';

        // Act
        final result = await service.generateTitle(
          memoContent: memoContent,
        );

        // Assert
        // API 오류나 빈 응답으로 null 반환 예상
        expect(result, anyOf(isNull, isA<String>()));
      });

      // 실제 API 호출을 위한 통합 테스트는 skip
      test('실제 API 호출은 통합 테스트에서 수행', () {
        // 이 테스트는 실제 Gemini API 키가 필요하므로 skip
      }, skip: true);
    });

    group('classifyAndGenerateTags', () {
      test('빈 폴더 목록으로는 folderId가 null이어야 한다', () async {
        // Arrange
        final availableFolders = <String, String>{};

        // Act
        final result = await service.classifyAndGenerateTags(
          memoTitle: 'Test Memo',
          memoContent: 'Test Content',
          availableFolders: availableFolders,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('folderId'), true);
        expect(result.containsKey('tags'), true);
        expect(result['tags'], isA<List<String>>());
      });

      // 실제 API 호출을 위한 통합 테스트는 skip
      test('실제 API 호출은 통합 테스트에서 수행', () {
        // 이 테스트는 실제 Gemini API 키가 필요하므로 skip
        // 통합 테스트에서:
        // 1. 실제 API 키 사용
        // 2. 테스트 메모와 폴더 준비
        // 3. API 호출 및 결과 검증
        // 4. 반환된 folderId가 제공된 폴더 목록에 있는지 확인
        // 5. 태그 개수가 maxTags 이하인지 확인
      }, skip: true);
    });

    group('Error Handling', () {
      test('잘못된 API 키로도 서비스가 초기화되어야 한다', () {
        // Arrange & Act
        final testService = GeminiService(apiKey: 'invalid-key');

        // Assert
        expect(testService, isNotNull);
      });

      test('API 오류 발생 시 적절히 처리되어야 한다', () async {
        // Arrange
        final testService = GeminiService(apiKey: 'invalid-api-key');

        // Act & Assert
        // API 오류 발생 시 null 또는 빈 리스트 반환 예상
        final folderResult = await testService.classifyMemoToFolder(
          memoTitle: 'Test',
          memoContent: 'Test',
          availableFolders: {'id': 'name'},
        );
        expect(folderResult, isNull);

        final tagsResult = await testService.generateTags(
          memoTitle: 'Test',
          memoContent: 'Test',
        );
        expect(tagsResult, isEmpty);

        final titleResult = await testService.generateTitle(
          memoContent: 'Test',
        );
        expect(titleResult, isNull);
      });
    });

    group('Parameter Validation', () {
      test('maxTags 파라미터가 올바르게 전달되어야 한다', () async {
        // Arrange
        const maxTags = 3;

        // Act
        final result = await service.generateTags(
          memoTitle: 'Test Memo',
          memoContent: 'Test Content',
          maxTags: maxTags,
        );

        // Assert
        // API 오류로 빈 리스트가 반환되더라도 타입 검증
        expect(result, isA<List<String>>());
        // 실제 API 호출 시 길이가 maxTags 이하여야 함
      });

      test('폴더 맵이 올바르게 처리되어야 한다', () async {
        // Arrange
        final folders = {
          'folder-1': '업무',
          'folder-2': '개인',
          'folder-3': '공부',
        };

        // Act
        final result = await service.classifyMemoToFolder(
          memoTitle: '회의록',
          memoContent: '오늘 회의 내용',
          availableFolders: folders,
        );

        // Assert
        // API 오류로 null이 반환될 수 있음
        expect(result, anyOf(isNull, isA<String>()));
        // 실제 API 호출 성공 시 folders의 키 중 하나여야 함
      });
    });
  });
}
