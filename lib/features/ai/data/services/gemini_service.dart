import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini API 서비스 클래스
/// 메모 분류, 태그 생성 등 AI 기능 제공
class GeminiService {
  late final GenerativeModel _model;
  final String apiKey;

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// 메모 내용을 분석하여 적절한 폴더 ID를 추천
  ///
  /// [memoTitle]: 메모 제목
  /// [memoContent]: 메모 본문
  /// [availableFolders]: 사용 가능한 폴더 목록 (Map<String, String> - id: name)
  ///
  /// Returns: 추천된 폴더 ID
  Future<String?> classifyMemoToFolder({
    required String memoTitle,
    required String memoContent,
    required Map<String, String> availableFolders,
  }) async {
    try {
      final folderList = availableFolders.entries
          .map((e) => '- ID: ${e.key}, 이름: ${e.value}')
          .join('\n');

      final prompt = '''
사용자가 작성한 메모를 분석하여 가장 적절한 폴더를 선택해주세요.

메모 제목: $memoTitle
메모 내용: $memoContent

사용 가능한 폴더:
$folderList

위 폴더 중에서 이 메모가 가장 잘 맞는 폴더의 ID만 응답해주세요.
오직 폴더 ID만 응답하고, 다른 설명은 포함하지 마세요.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final folderId = response.text?.trim();

      // 응답이 유효한 폴더 ID인지 확인
      if (folderId != null && availableFolders.containsKey(folderId)) {
        return folderId;
      }

      return null;
    } catch (e) {
      print('Error classifying memo: $e');
      return null;
    }
  }

  /// 메모 내용을 분석하여 관련 태그를 자동 생성
  ///
  /// [memoTitle]: 메모 제목
  /// [memoContent]: 메모 본문
  /// [maxTags]: 최대 태그 개수 (기본값: 5)
  ///
  /// Returns: 생성된 태그 목록
  Future<List<String>> generateTags({
    required String memoTitle,
    required String memoContent,
    int maxTags = 5,
  }) async {
    try {
      final prompt = '''
다음 메모의 내용을 분석하여 관련 태그를 생성해주세요.

메모 제목: $memoTitle
메모 내용: $memoContent

조건:
- 최대 $maxTags개의 태그만 생성
- 각 태그는 짧고 명확하게 (2-10자 이내)
- 태그는 쉼표(,)로 구분
- 태그만 응답하고 다른 설명은 포함하지 마세요
- 예시: 업무, 프로젝트, 마감기한, 중요

태그:
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final tagsText = response.text?.trim();

      if (tagsText == null || tagsText.isEmpty) {
        return [];
      }

      // 쉼표로 구분된 태그를 리스트로 변환
      final tags = tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .take(maxTags)
          .toList();

      return tags;
    } catch (e) {
      print('Error generating tags: $e');
      return [];
    }
  }

  /// 메모 제목이 없을 때 내용을 기반으로 제목 자동 생성
  ///
  /// [memoContent]: 메모 본문
  ///
  /// Returns: 생성된 제목
  Future<String?> generateTitle({required String memoContent}) async {
    try {
      final prompt = '''
다음 메모 내용을 요약하여 간단한 제목을 만들어주세요.

메모 내용: $memoContent

조건:
- 제목은 10자 이내로 간결하게
- 메모의 핵심 내용을 담아야 함
- 제목만 응답하고 다른 설명은 포함하지 마세요
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      print('Error generating title: $e');
      return null;
    }
  }

  /// 메모 내용을 분석하여 폴더와 태그를 동시에 추천
  ///
  /// [memoTitle]: 메모 제목
  /// [memoContent]: 메모 본문
  /// [availableFolders]: 사용 가능한 폴더 목록
  /// [maxTags]: 최대 태그 개수
  ///
  /// Returns: Map with 'folderId' and 'tags'
  Future<Map<String, dynamic>> classifyAndGenerateTags({
    required String memoTitle,
    required String memoContent,
    required Map<String, String> availableFolders,
    int maxTags = 5,
  }) async {
    try {
      final folderList = availableFolders.entries
          .map((e) => '- ID: ${e.key}, 이름: ${e.value}')
          .join('\n');

      final prompt = '''
사용자가 작성한 메모를 분석하여 적절한 폴더를 선택하고 관련 태그를 생성해주세요.

메모 제목: $memoTitle
메모 내용: $memoContent

사용 가능한 폴더:
$folderList

다음 형식으로만 응답해주세요:
폴더ID: [폴더 ID]
태그: [태그1, 태그2, 태그3]

조건:
- 폴더 ID는 위 목록 중 하나여야 함
- 태그는 최대 $maxTags개, 쉼표로 구분
- 각 태그는 2-10자 이내
- 위 형식 외 다른 설명은 포함하지 마세요
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();

      if (text == null) {
        return {'folderId': null, 'tags': <String>[]};
      }

      // 응답 파싱
      String? folderId;
      List<String> tags = [];

      final lines = text.split('\n');
      for (final line in lines) {
        if (line.startsWith('폴더ID:')) {
          final id = line.substring('폴더ID:'.length).trim();
          if (availableFolders.containsKey(id)) {
            folderId = id;
          }
        } else if (line.startsWith('태그:')) {
          final tagsText = line.substring('태그:'.length).trim();
          tags = tagsText
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .take(maxTags)
              .toList();
        }
      }

      return {'folderId': folderId, 'tags': tags};
    } catch (e) {
      print('Error in classifyAndGenerateTags: $e');
      return {'folderId': null, 'tags': <String>[]};
    }
  }
}
