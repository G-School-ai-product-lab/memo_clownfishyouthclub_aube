import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../memo/presentation/providers/folder_providers.dart';

class FolderShortcutsSection extends ConsumerWidget {
  const FolderShortcutsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '폴더',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: foldersAsync.when(
            data: (folders) {
              if (folders.isEmpty) {
                return const Center(
                  child: Text(
                    '폴더가 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: folders.length + 1, // +1 for "전체" folder
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFolderCard(
                      icon: '📁',
                      name: '전체',
                      count: folders.fold<int>(
                        0,
                        (sum, folder) => sum + folder.memoCount,
                      ),
                      onTap: () {
                        // TODO: 전체 메모 보기
                      },
                    );
                  }

                  final folder = folders[index - 1];
                  return _buildFolderCard(
                    icon: folder.icon,
                    name: folder.name,
                    count: folder.memoCount,
                    onTap: () {
                      // TODO: 폴더별 메모 보기
                    },
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B4444),
              ),
            ),
            error: (error, stack) => Center(
              child: Text('오류: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderCard({
    required String icon,
    required String name,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$count개',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
