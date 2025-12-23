import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memo.dart';
import '../../domain/entities/folder.dart';
import '../providers/memo_providers.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../providers/folder_providers.dart';
import '../providers/tag_providers.dart';

class MemoEditScreen extends ConsumerStatefulWidget {
  final Memo memo;

  const MemoEditScreen({
    super.key,
    required this.memo,
  });

  @override
  ConsumerState<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends ConsumerState<MemoEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  bool _isClassifying = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo.title);
    _contentController = TextEditingController(text: widget.memo.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// AI를 사용하여 메모 재분류
  Future<void> _reclassifyWithAI() async {
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
        userId: widget.memo.userId,
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
              userId: widget.memo.userId,
              tagRepository: tagRepository,
            );
          }

          // AI 분류 결과를 메모에 적용하고 저장
          final repository = ref.read(memoRepositoryProvider);
          final updatedMemo = Memo(
            id: widget.memo.id,
            userId: widget.memo.userId,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            tags: result.tags,
            folderId: result.folderId,
            createdAt: widget.memo.createdAt,
            updatedAt: DateTime.now(),
            isPinned: widget.memo.isPinned,
          );

          await repository.updateMemo(updatedMemo);
          ref.invalidate(memosStreamProvider);

          // 폴더가 새로 생성되었으면 provider 갱신
          if (result.newFolderCreated) {
            ref.invalidate(foldersStreamProvider);
          }

          if (!mounted) return;

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
      final repository = ref.read(memoRepositoryProvider);
      final updatedMemo = Memo(
        id: widget.memo.id,
        userId: widget.memo.userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: widget.memo.tags,
        folderId: widget.memo.folderId,
        createdAt: widget.memo.createdAt,
        updatedAt: DateTime.now(),
        isPinned: widget.memo.isPinned,
      );

      await repository.updateMemo(updatedMemo);

      if (mounted) {
        // Provider 갱신
        ref.invalidate(memosStreamProvider);

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 수정되었습니다'),
            backgroundColor: Color(0xFF8B4444),
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
              onPressed: _reclassifyWithAI,
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
