import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../memo/presentation/providers/filter_providers.dart';
import '../../../memo/presentation/providers/folder_providers.dart';
import '../../../memo/presentation/providers/memo_providers.dart';
import '../../../memo/presentation/screens/all_memos_screen.dart';

class FolderShortcutsSection extends ConsumerWidget {
  const FolderShortcutsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersStreamProvider);
    final userId = ref.watch(currentUserIdProvider);

    // 디버깅: userId와 폴더 상태 로그
    AppLogger.d('FolderShortcutsSection - userId: $userId');
    foldersAsync.whenData((folders) {
      AppLogger.d('FolderShortcutsSection - folders count: ${folders.length}');
      for (var folder in folders) {
        AppLogger.d('  - ${folder.name} (${folder.id}): ${folder.memoCount}개');
      }
    });

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
        // ✅ height를 살짝 여유 있게 (iOS 폰트/라인하이트로 인한 overflow 방지)
        SizedBox(
          height: 112,
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
                        // 필터 해제
                        ref.read(memoFilterProvider.notifier).clearFilter();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllMemosScreen(),
                          ),
                        );
                      },
                    );
                  }

                  final folder = folders[index - 1];
                  return _buildFolderCard(
                    icon: folder.icon,
                    name: folder.name,
                    count: folder.memoCount,
                    onTap: () {
                      // 폴더 필터 적용
                      ref
                          .read(memoFilterProvider.notifier)
                          .setFolderFilter(folder);
                      // 전체 메모 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllMemosScreen(),
                        ),
                      );
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
        alignment: Alignment.center, // ✅ 가운데 정렬 고정
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
          mainAxisSize: MainAxisSize.min, // ✅ 내용만큼만 높이 사용 (overflow 방지)
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(
                fontSize: 32,
                height: 1.0, // ✅ 이모지 라인하이트로 아래로 밀리는 것 방지
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.1, // ✅ 텍스트 줄높이 살짝 고정
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
                height: 1.0, // ✅ iOS에서 아래로 밀려 overflow 나는 것 방지
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }
}
