import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/folder.dart';
import '../providers/folder_providers.dart';
import '../../../../core/utils/app_logger.dart';

class FolderEditScreen extends ConsumerStatefulWidget {
  final Folder folder;

  const FolderEditScreen({
    super.key,
    required this.folder,
  });

  @override
  ConsumerState<FolderEditScreen> createState() => _FolderEditScreenState();
}

class _FolderEditScreenState extends ConsumerState<FolderEditScreen> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _icons = [
    '📁', '📂', '📋', '📌', '📝', '📖',
    '💼', '🏠', '🎯', '💡', '🎨', '🔬',
    '📚', '🎓', '💻', '📱', '🎵', '🎮',
  ];

  final Map<String, Color> _colors = {
    'blue': Colors.blue,
    'red': Colors.red,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'amber': Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
    _selectedIcon = widget.folder.icon;
    _selectedColor = widget.folder.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveFolder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('폴더 이름을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final folderName = _nameController.text.trim();
      final folderRepository = ref.read(folderRepositoryProvider);

      // 이름이 변경된 경우 중복 체크
      if (folderName != widget.folder.name) {
        final existingFolder = await folderRepository.getFolderByName(
          widget.folder.userId,
          folderName,
        );
        if (existingFolder != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미 "$folderName" 폴더가 존재합니다'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final updatedFolder = widget.folder.copyWith(
        name: folderName,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      await folderRepository.updateFolder(updatedFolder);

      AppLogger.i('폴더 수정 완료: ${updatedFolder.name}');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedFolder.name} 폴더가 수정되었습니다'),
            backgroundColor: const Color(0xFF8B4444),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('폴더 수정 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('폴더 수정 실패: $e'),
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

  Future<void> _deleteFolder() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text(
          '${widget.folder.name} 폴더를 삭제하시겠습니까?\n\n'
          '폴더를 삭제해도 메모는 삭제되지 않으며,\n'
          '분류되지 않은 메모로 남게 됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final folderRepository = ref.read(folderRepositoryProvider);
      await folderRepository.deleteFolder(widget.folder.id);

      AppLogger.i('폴더 삭제 완료: ${widget.folder.name}');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.folder.name} 폴더가 삭제되었습니다'),
            backgroundColor: const Color(0xFF8B4444),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('폴더 삭제 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('폴더 삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
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
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '폴더 수정',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSaving)
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
              onPressed: _saveFolder,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 폴더 이름 입력
            const Text(
              '폴더 이름',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '예: 업무, 개인, 공부',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 아이콘 선택
            const Text(
              '아이콘',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B4444).withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF8B4444)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // 색상 선택
            const Text(
              '색상',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.entries.map((entry) {
                final isSelected = entry.key == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = entry.key;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 48),

            // 삭제 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _deleteFolder,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  _isDeleting ? '삭제 중...' : '폴더 삭제',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
