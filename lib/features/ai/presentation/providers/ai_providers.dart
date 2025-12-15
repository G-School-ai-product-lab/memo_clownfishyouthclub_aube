import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/gemini_service.dart';
import '../../../memo/domain/entities/folder.dart';
import '../../../memo/domain/entities/tag.dart';
import '../../../memo/domain/repositories/tag_repository.dart';

/// Gemini 서비스 Provider
final geminiServiceProvider = Provider<GeminiService?>((ref) {
  if (!EnvConfig.hasGeminiApiKey) {
    AppLogger.w('Gemini API 키가 설정되지 않았습니다.');
    return null;
  }
  AppLogger.i('Gemini API 키 확인됨: ${EnvConfig.geminiApiKey.substring(0, 10)}...');
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
      AppLogger.w('AI 분류 시도했으나 geminiService가 null입니다.');
      return ClassificationResult(
        folderId: null,
        tags: [],
        error: 'AI 서비스를 사용할 수 없습니다. API 키를 설정해주세요.',
      );
    }

    try {
      AppLogger.i('AI 분류 시작 - 제목: $title, 폴더 수: ${folders.length}');

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

      AppLogger.i('AI 분류 완료 - 폴더: ${result['folderId']}, 태그: ${result['tags']}');

      return ClassificationResult(
        folderId: result['folderId'] as String?,
        tags: result['tags'] as List<String>,
        error: null,
      );
    } catch (e, stackTrace) {
      AppLogger.e('AI 분류 중 오류', error: e, stackTrace: stackTrace);
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

/// AI가 생성한 태그를 자동으로 데이터베이스에 생성하는 헬퍼 함수
Future<void> ensureTagsExist({
  required List<String> tagNames,
  required String userId,
  required TagRepository tagRepository,
}) async {
  if (tagNames.isEmpty) return;

  // 태그 색상 팔레트
  const tagColors = [
    '#FF6B6B', // 빨강
    '#4ECDC4', // 청록
    '#45B7D1', // 하늘색
    '#FFA07A', // 연어색
    '#98D8C8', // 민트
    '#F7DC6F', // 노랑
    '#BB8FCE', // 보라
    '#85C1E2', // 파랑
    '#F8B88B', // 오렌지
    '#ABEBC6', // 연두
  ];

  final tagsToCreate = <Tag>[];
  int colorIndex = 0;

  for (final tagName in tagNames) {
    // 기존 태그가 있는지 확인
    final existingTag = await tagRepository.getTagByName(userId, tagName);

    if (existingTag == null) {
      // 태그가 없으면 생성 목록에 추가
      tagsToCreate.add(Tag(
        id: '', // datasource에서 자동 생성
        userId: userId,
        name: tagName,
        color: tagColors[colorIndex % tagColors.length],
        memoCount: 0,
        createdAt: DateTime.now(),
      ));
      colorIndex++;
    }
  }

  // 새로운 태그가 있으면 배치 생성
  if (tagsToCreate.isNotEmpty) {
    await tagRepository.createTags(tagsToCreate);
    AppLogger.i('새로운 태그 ${tagsToCreate.length}개 생성됨: ${tagsToCreate.map((t) => t.name).join(", ")}');
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
