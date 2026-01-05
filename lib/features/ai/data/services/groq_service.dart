import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';

/// Groq API 서비스 클래스
/// 메모 분류, 태그 생성 등 AI 기능 제공
class GroqService {
  final String apiKey;
  final String baseUrl = 'https://api.groq.com/openai/v1';
  final String model = 'llama-3.3-70b-versatile'; // 한국어 지원이 우수한 모델

  GroqService({required this.apiKey}) {
    AppLogger.i('🔧 Groq Service initialized: model=$model, apiKey=${apiKey.substring(0, 10)}...');
  }

  /// Groq API 호출
  Future<String?> _generateContent(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      } else {
        AppLogger.e('Groq API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error calling Groq API', error: e, stackTrace: stackTrace);
      return null;
    }
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

      final folderId = await _generateContent(prompt);

      // 응답이 유효한 폴더 ID인지 확인
      if (folderId != null && availableFolders.containsKey(folderId.trim())) {
        return folderId.trim();
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Error classifying memo', error: e, stackTrace: stackTrace);
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

      final tagsText = await _generateContent(prompt);

      if (tagsText == null || tagsText.trim().isEmpty) {
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
    } catch (e, stackTrace) {
      AppLogger.e('Error generating tags', error: e, stackTrace: stackTrace);
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

      final title = await _generateContent(prompt);
      return title?.trim();
    } catch (e, stackTrace) {
      AppLogger.e('Error generating title', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 메모 내용을 분석하여 폴더와 태그를 동시에 추천
  ///
  /// [memoTitle]: 메모 제목
  /// [memoContent]: 메모 본문
  /// [availableFolders]: 사용 가능한 폴더 목록
  /// [maxTags]: 최대 태그 개수
  /// [allowNewFolder]: 새 폴더 생성 허용 여부
  ///
  /// Returns: Map with 'folderId', 'tags', 'newFolder' (name, icon, color)
  Future<Map<String, dynamic>> classifyAndGenerateTags({
    required String memoTitle,
    required String memoContent,
    required Map<String, String> availableFolders,
    int maxTags = 5,
    bool allowNewFolder = true,
  }) async {
    try {
      final folderList = availableFolders.isEmpty
          ? '없음'
          : availableFolders.entries
              .map((e) => '- ID: ${e.key}, 이름: ${e.value}')
              .join('\n');

      final prompt = availableFolders.isEmpty || allowNewFolder
          ? '''
사용자가 작성한 메모를 분석하여 적절한 폴더를 선택하거나 새 폴더를 제안하고, 관련 태그를 생성해주세요.

메모 제목: $memoTitle
메모 내용: $memoContent

${availableFolders.isEmpty ? '현재 폴더가 없습니다.' : '''사용 가능한 기존 폴더:
$folderList'''}

다음 형식으로만 응답해주세요:

경우 1 - 기존 폴더를 사용하는 경우:
폴더ID: [폴더 ID]
태그: [태그1, 태그2, 태그3]

경우 2 - 새 폴더를 제안하는 경우:
새폴더: [폴더명]
아이콘: [이모지 1개]
색상: [blue/red/green/purple/orange/pink/yellow/teal/indigo/gray 중 하나]
태그: [태그1, 태그2, 태그3]

조건:
- 기존 폴더 중 적절한 것이 있으면 경우 1로 응답
- 기존 폴더가 없거나 맞는 것이 없으면 경우 2로 새 폴더 제안
- 새 폴더명은 2-10자 이내로 간결하게
- 아이콘은 이모지 1개만 (예: 📝, 💼, 🎯, 📚, 💡)
- 태그는 최대 $maxTags개, 쉼표로 구분
- 각 태그는 2-10자 이내
- 위 형식 외 다른 설명은 포함하지 마세요
'''
          : '''
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

      final text = await _generateContent(prompt);

      if (text == null) {
        return {'folderId': null, 'tags': <String>[], 'newFolder': null};
      }

      // 응답 파싱
      String? folderId;
      List<String> tags = [];
      Map<String, String>? newFolder;

      final lines = text.split('\n');
      for (final line in lines) {
        if (line.startsWith('폴더ID:')) {
          final id = line.substring('폴더ID:'.length).trim();
          if (availableFolders.containsKey(id)) {
            folderId = id;
          }
        } else if (line.startsWith('새폴더:')) {
          final name = line.substring('새폴더:'.length).trim();
          newFolder = {'name': name, 'icon': '📁', 'color': 'blue'};
        } else if (line.startsWith('아이콘:') && newFolder != null) {
          final icon = line.substring('아이콘:'.length).trim();
          newFolder['icon'] = icon;
        } else if (line.startsWith('색상:') && newFolder != null) {
          final color = line.substring('색상:'.length).trim();
          newFolder['color'] = color;
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

      AppLogger.i('🎯 Groq 분류 결과 - folderId: $folderId, tags: $tags, newFolder: $newFolder');

      return {
        'folderId': folderId,
        'tags': tags,
        'newFolder': newFolder,
      };
    } catch (e, stackTrace) {
      AppLogger.e('Error in classifyAndGenerateTags',
          error: e, stackTrace: stackTrace);
      return {'folderId': null, 'tags': <String>[], 'newFolder': null};
    }
  }
}
