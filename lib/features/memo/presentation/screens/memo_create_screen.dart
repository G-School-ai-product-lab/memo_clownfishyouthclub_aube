import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/memo.dart';
import '../providers/memo_providers.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../providers/folder_providers.dart';
import '../providers/tag_providers.dart';

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
      if (!foldersAsync.hasValue || foldersAsync.value!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('폴더를 먼저 생성해주세요'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final folders = foldersAsync.value!;
      final result = await aiService.classifyMemo(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        folders: folders,
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

          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'AI가 자동으로 분류했습니다!\n'
                '${result.folderId != null ? '폴더 지정됨 | ' : ''}'
                '${result.tags.isNotEmpty ? '태그: ${result.tags.join(", ")}' : ''}',
              ),
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
      await _saveMemoWithClassification(
        userId: userId,
        folderId: null,
        tags: [],
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 생성되었습니다'),
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

  Future<void> _saveMemoWithClassification({
    required String userId,
    String? folderId,
    List<String> tags = const [],
  }) async {
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

    final repository = ref.read(memoRepositoryProvider);
    await repository.createMemo(memo);
    ref.invalidate(memosStreamProvider);
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
