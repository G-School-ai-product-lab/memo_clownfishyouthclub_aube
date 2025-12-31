import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/memo.dart';
import '../../domain/entities/folder.dart';
import '../providers/memo_providers.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../providers/folder_providers.dart';
import '../providers/tag_providers.dart';
import '../../../../core/utils/app_logger.dart';

class MemoCreateScreen extends ConsumerStatefulWidget {
  const MemoCreateScreen({super.key});

  @override
  ConsumerState<MemoCreateScreen> createState() => _MemoCreateScreenState();
}

class _MemoCreateScreenState extends ConsumerState<MemoCreateScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  bool _isClassifying = false;

  // 수동 선택된 폴더와 태그
  String? _selectedFolderId;
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// AI를 사용하여 메모 자동 분류
  Future<void> _classifyWithAI() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목이나 내용을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isClassifying = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 필요합니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final aiService = ref.read(aiClassificationServiceProvider);

      if (!aiService.isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI 서비스를 사용할 수 없습니다. API 키를 설정해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final foldersAsync = ref.read(foldersStreamProvider);
      final folders = foldersAsync.hasValue ? foldersAsync.value! : <Folder>[];
      final folderRepository = ref.read(folderRepositoryProvider);

      final result = await aiService.classifyMemo(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        folders: folders,
        userId: userId,
        folderRepository: folderRepository,
        allowNewFolder: true,
      );

      if (mounted) {
        if (result.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // AI가 생성한 태그를 데이터베이스에 자동 생성
          if (result.tags.isNotEmpty) {
            final tagRepository = ref.read(tagRepositoryProvider);
            await ensureTagsExist(
              tagNames: result.tags,
              userId: userId,
              tagRepository: tagRepository,
            );
          }

          // AI 분류 결과로 메모 생성 및 저장
          await _saveMemoWithClassification(
            userId: userId,
            folderId: result.folderId,
            tags: result.tags,
          );

          if (!mounted) return;

          // 폴더가 새로 생성되었으면 provider 갱신
          if (result.newFolderCreated) {
            ref.invalidate(foldersStreamProvider);
          }

          Navigator.pop(context, true);

          String message = 'AI가 자동으로 분류했습니다!\n';
          if (result.newFolderCreated) {
            message += '새 폴더 생성됨 | ';
          } else if (result.folderId != null) {
            message += '폴더 지정됨 | ';
          }
          if (result.tags.isNotEmpty) {
            message += '태그: ${result.tags.join(", ")}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF8B4444),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 분류 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClassifying = false;
        });
      }
    }
  }

  Future<void> _saveMemo() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목이나 내용을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 수동 선택이 있으면 우선 사용, 없으면 AI 자동 분류 시도
      String? folderId = _selectedFolderId;
      List<String> tags = _selectedTags.toList();
      bool newFolderCreated = false;

      // 수동 선택이 없고 AI 서비스가 사용 가능한 경우에만 AI 분류
      final aiService = ref.read(aiClassificationServiceProvider);
      if (folderId == null && tags.isEmpty && aiService.isAvailable) {
        try {
          final foldersAsync = ref.read(foldersStreamProvider);
          final folders = foldersAsync.hasValue ? foldersAsync.value! : <Folder>[];
          final folderRepository = ref.read(folderRepositoryProvider);

          final result = await aiService.classifyMemo(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            folders: folders,
            userId: userId,
            folderRepository: folderRepository,
            allowNewFolder: true,
          );

          if (!result.hasError) {
            folderId = result.folderId;
            tags = result.tags;
            newFolderCreated = result.newFolderCreated;

            // AI가 생성한 태그를 데이터베이스에 먼저 생성 (메모 저장 전에!)
            if (tags.isNotEmpty) {
              final tagRepository = ref.read(tagRepositoryProvider);
              await ensureTagsExist(
                tagNames: tags,
                userId: userId,
                tagRepository: tagRepository,
              );

              // 태그 생성이 완료될 때까지 잠시 대기
              await Future.delayed(const Duration(milliseconds: 200));
            }

            // 폴더가 새로 생성되었으면 provider 갱신하고 완료될 때까지 대기
            if (newFolderCreated) {
              ref.invalidate(foldersStreamProvider);
              // 폴더 생성이 완료될 때까지 잠시 대기
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }
        } catch (e) {
          // AI 분류 실패해도 메모는 저장
          AppLogger.w('AI 자동 분류 실패, 메모는 저장됩니다', error: e);
        }
      }

      await _saveMemoWithClassification(
        userId: userId,
        folderId: folderId,
        tags: tags,
      );

      if (mounted) {
        Navigator.pop(context, true);

        String message = '메모가 생성되었습니다';
        if (folderId != null || tags.isNotEmpty) {
          message = 'AI가 자동으로 분류했습니다!\n';
          if (newFolderCreated) {
            message += '새 폴더 생성됨 | ';
          } else if (folderId != null) {
            message += '폴더 지정됨 | ';
          }
          if (tags.isNotEmpty) {
            message += '태그: ${tags.join(", ")}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF8B4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveMemoWithClassification({
    required String userId,
    String? folderId,
    List<String> tags = const [],
  }) async {
    AppLogger.i('메모 저장 시작 - folderId: $folderId, tags: $tags');

    final now = DateTime.now();
    final memo = Memo(
      id: const Uuid().v4(),
      userId: userId,
      title: _titleController.text.trim().isEmpty
          ? '제목 없음'
          : _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: tags,
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
    );

    AppLogger.i('생성된 메모: id=${memo.id}, folderId=${memo.folderId}, tags=${memo.tags}');

    final repository = ref.read(memoRepositoryProvider);
    await repository.createMemo(memo);

    AppLogger.i('메모 저장 완료');
    ref.invalidate(memosStreamProvider);
  }

  Widget _buildFolderTagSelector() {
    final foldersAsync = ref.watch(foldersStreamProvider);
    final tagsAsync = ref.watch(tagsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 폴더 선택
        foldersAsync.when(
          data: (folders) {
            if (folders.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text(
                      '폴더',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: folders.map((folder) {
                    final isSelected = _selectedFolderId == folder.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFolderId = isSelected ? null : folder.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B4444).withAlpha(51)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B4444)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(folder.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              folder.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? const Color(0xFF8B4444) : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // 태그 선택
        tagsAsync.when(
          data: (tags) {
            if (tags.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tag, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text(
                      '태그',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final isSelected = _selectedTags.contains(tag.name);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag.name);
                          } else {
                            _selectedTags.add(tag.name);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B4444).withAlpha(51)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B4444)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '#${tag.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? const Color(0xFF8B4444) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isClassifying && !_isSaving)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFF8B4444)),
              onPressed: _classifyWithAI,
              tooltip: 'AI 자동분류',
            ),
          if (_isClassifying || _isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF8B4444),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveMemo,
              child: const Text(
                '완료',
                style: TextStyle(
                  color: Color(0xFF8B4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 내용 입력 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 입력
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: '제목',
                      hintStyle: TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),

                  // 폴더/태그 선택 영역
                  _buildFolderTagSelector(),

                  const SizedBox(height: 16),
                  // 내용 입력
                  TextField(
                    controller: _contentController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                    decoration: const InputDecoration(
                      hintText: '내용을 입력하세요...',
                      hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 20,
                  ),
                ],
              ),
            ),
          ),

          // 하단 툴바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.format_size,
                    label: '가',
                    onPressed: () {
                      // TODO: 텍스트 스타일 기능
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted,
                    onPressed: () {
                      // TODO: 리스트 기능
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.table_chart,
                    onPressed: () {
                      // TODO: 테이블 기능
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.image_outlined,
                    onPressed: () {
                      // TODO: 이미지 기능
                    },
                  ),
                  const Spacer(),
                  _ToolbarButton(
                    icon: Icons.share_outlined,
                    onPressed: () {
                      // TODO: 공유 기능
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 툴바 버튼 위젯
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: label != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: Colors.black87),
                  const SizedBox(width: 4),
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Icon(icon, size: 22, color: Colors.black87),
      ),
    );
  }
}
