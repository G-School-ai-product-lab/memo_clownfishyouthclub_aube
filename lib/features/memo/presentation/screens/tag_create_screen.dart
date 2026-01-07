import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tag.dart';
import '../providers/tag_providers.dart';
import '../providers/memo_providers.dart';
import '../providers/folder_providers.dart';
import '../../../../core/utils/app_logger.dart';

class TagCreateScreen extends ConsumerStatefulWidget {
  const TagCreateScreen({super.key});

  @override
  ConsumerState<TagCreateScreen> createState() => _TagCreateScreenState();
}

class _TagCreateScreenState extends ConsumerState<TagCreateScreen> {
  final _nameController = TextEditingController();
  String _selectedColor = '#FF6B6B';
  bool _isSaving = false;

  final List<String> _colors = [
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _saveTag() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('태그 이름을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      final tagName = _nameController.text.trim();
      final tagRepository = ref.read(tagRepositoryProvider);
      final folderRepository = ref.read(folderRepositoryProvider);

      // 1. 같은 이름의 태그가 이미 있는지 확인
      final existingTag = await tagRepository.getTagByName(userId, tagName);
      if (existingTag != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미 "#$tagName" 태그가 존재합니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. 같은 이름의 폴더가 있는지 확인
      final existingFolder = await folderRepository.getFolderByName(userId, tagName);

      if (existingFolder != null) {
        // 폴더가 있으면 안내 메시지만 표시
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('폴더가 이미 존재합니다'),
            content: Text(
              '"$tagName" 이름의 폴더가 이미 존재합니다.\n'
              '폴더를 사용하시거나 다른 이름의 태그를 만들어주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '확인',
                  style: TextStyle(color: Color(0xFF8B4444)),
                ),
              ),
            ],
          ),
        );

        setState(() => _isSaving = false);
        return;
      }

      // 일반 태그 생성
      final tag = Tag(
        id: '', // datasource에서 자동 생성
        userId: userId,
        name: tagName,
        color: _selectedColor,
        memoCount: 0,
        createdAt: DateTime.now(),
      );

      await tagRepository.createTag(tag);

      AppLogger.i('태그 생성 완료: ${tag.name}');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('#${tag.name} 태그가 생성되었습니다'),
            backgroundColor: const Color(0xFF8B4444),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('태그 생성 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('태그 생성 실패: $e'),
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
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '새 태그',
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
              onPressed: _saveTag,
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
            // 태그 이름 입력
            const Text(
              '태그 이름',
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
                hintText: '예: 중요, 아이디어, 할일',
                prefixText: '# ',
                prefixStyle: TextStyle(
                  color: _hexToColor(_selectedColor),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
              onChanged: (value) {
                setState(() {}); // Rebuild to update prefix color
              },
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
              children: _colors.map((colorHex) {
                final isSelected = colorHex == _selectedColor;
                final color = _hexToColor(colorHex);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
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

            const SizedBox(height: 32),

            // 미리보기
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '미리보기',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _hexToColor(_selectedColor).withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _hexToColor(_selectedColor),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _nameController.text.trim().isEmpty
                              ? '태그이름'
                              : '#${_nameController.text.trim()}',
                          style: TextStyle(
                            color: _hexToColor(_selectedColor),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
