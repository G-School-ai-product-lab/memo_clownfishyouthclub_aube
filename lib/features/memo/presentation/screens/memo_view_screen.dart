import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memo.dart';
import '../providers/memo_providers.dart';
import 'memo_edit_screen.dart';

class MemoViewScreen extends ConsumerWidget {
  final Memo memo;

  const MemoViewScreen({
    super.key,
    required this.memo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF8B4444)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemoEditScreen(memo: memo),
                ),
              ).then((updated) {
                if (updated == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              });
            },
            tooltip: '편집',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('메모 삭제'),
                  content: const Text('이 메모를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  final repository = ref.read(memoRepositoryProvider);
                  await repository.deleteMemo(memo.id);
                  ref.invalidate(memosStreamProvider);

                  if (context.mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('메모가 삭제되었습니다'),
                        backgroundColor: Color(0xFF8B4444),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('삭제 실패: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            tooltip: '삭제',
          ),
        ],
      ),
      body: Column(
        children: [
          // 내용 표시 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  if (memo.title.isNotEmpty) ...[
                    Text(
                      memo.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 내용
                  Text(
                    memo.content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),

                  // 태그
                  if (memo.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: memo.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
                  const Spacer(),
                  _ToolbarButton(
                    icon: Icons.share_outlined,
                    onPressed: () async {
                      final shareText = memo.title.isNotEmpty
                          ? '${memo.title}\n\n${memo.content}'
                          : memo.content;
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('클립보드에 복사되었습니다'),
                            backgroundColor: Color(0xFF8B4444),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
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
