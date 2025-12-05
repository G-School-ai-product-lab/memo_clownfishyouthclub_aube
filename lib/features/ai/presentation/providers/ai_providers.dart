import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/env_config.dart';
import '../../data/services/gemini_service.dart';
import '../../../memo/domain/entities/folder.dart';

/// Gemini 서비스 Provider
final geminiServiceProvider = Provider<GeminiService?>((ref) {
  if (!EnvConfig.hasGeminiApiKey) {
    return null;
  }
  return GeminiService(apiKey: EnvConfig.geminiApiKey);
});

/// AI 자동 분류 서비스 Provider
final aiClassificationServiceProvider = Provider<AiClassificationService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return AiClassificationService(geminiService: geminiService);
});

/// AI 자동 분류 서비스
class AiClassificationService {
  final GeminiService? geminiService;

  AiClassificationService({required this.geminiService});

  /// AI가 사용 가능한지 확인
  bool get isAvailable => geminiService != null;

  /// 메모를 자동으로 분류하고 태그 생성
  Future<ClassificationResult> classifyMemo({
    required String title,
    required String content,
    required List<Folder> folders,
  }) async {
    if (geminiService == null) {
      return ClassificationResult(
        folderId: null,
        tags: [],
        error: 'AI 서비스를 사용할 수 없습니다. API 키를 설정해주세요.',
      );
    }

    try {
      // 폴더 목록을 Map으로 변환
      final folderMap = {
        for (var folder in folders) folder.id: folder.name,
      };

      // AI로 폴더와 태그 동시 분류
      final result = await geminiService!.classifyAndGenerateTags(
        memoTitle: title,
        memoContent: content,
        availableFolders: folderMap,
        maxTags: 5,
      );

      return ClassificationResult(
        folderId: result['folderId'] as String?,
        tags: result['tags'] as List<String>,
        error: null,
      );
    } catch (e) {
      return ClassificationResult(
        folderId: null,
        tags: [],
        error: 'AI 분류 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 메모 제목 자동 생성
  Future<String?> generateTitle(String content) async {
    if (geminiService == null) return null;
    try {
      return await geminiService!.generateTitle(memoContent: content);
    } catch (e) {
      return null;
    }
  }

  /// 폴더만 분류
  Future<String?> classifyToFolder({
    required String title,
    required String content,
    required List<Folder> folders,
  }) async {
    if (geminiService == null) return null;

    try {
      final folderMap = {
        for (var folder in folders) folder.id: folder.name,
      };

      return await geminiService!.classifyMemoToFolder(
        memoTitle: title,
        memoContent: content,
        availableFolders: folderMap,
      );
    } catch (e) {
      return null;
    }
  }

  /// 태그만 생성
  Future<List<String>> generateTags({
    required String title,
    required String content,
  }) async {
    if (geminiService == null) return [];

    try {
      return await geminiService!.generateTags(
        memoTitle: title,
        memoContent: content,
        maxTags: 5,
      );
    } catch (e) {
      return [];
    }
  }
}

/// AI 분류 결과
class ClassificationResult {
  final String? folderId;
  final List<String> tags;
  final String? error;

  ClassificationResult({
    required this.folderId,
    required this.tags,
    this.error,
  });

  bool get hasError => error != null;
  bool get isSuccess => !hasError;
}
