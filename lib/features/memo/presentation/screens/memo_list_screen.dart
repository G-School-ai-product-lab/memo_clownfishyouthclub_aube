import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/memo.dart';
import '../providers/memo_providers.dart';

class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('파묘'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: memosAsync.when(
        data: (memos) {
          if (memos.isEmpty) {
            return const Center(
              child: Text('메모가 없습니다.\n\n+ 버튼을 눌러 새 메모를 작성해보세요!'),
            );
          }
          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return _MemoListItem(memo: memo);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMemoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateMemoDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 메모'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '메모 제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '메모 내용을 입력하세요',
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) {
                Navigator.pop(context);
                return;
              }

              final now = DateTime.now();
              final memo = Memo(
                id: const Uuid().v4(),
                userId: userId,
                title: titleController.text.isEmpty
                    ? '제목 없음'
                    : titleController.text,
                content: contentController.text,
                tags: [],
                createdAt: now,
                updatedAt: now,
              );

              final repository = ref.read(memoRepositoryProvider);
              await repository.createMemo(memo);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

class _MemoListItem extends ConsumerWidget {
  final Memo memo;

  const _MemoListItem({required this.memo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          memo.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              memo.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (memo.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: memo.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteMemo(context, ref),
        ),
        onTap: () => _showMemoDetail(context),
      ),
    );
  }

  void _showMemoDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(memo.title),
        content: SingleChildScrollView(
          child: Text(memo.content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMemo(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repository = ref.read(memoRepositoryProvider);
      await repository.deleteMemo(memo.id);
    }
  }
}
