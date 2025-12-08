import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memo.dart';
import '../providers/memo_providers.dart';
import '../providers/filter_providers.dart';

class AllMemosScreen extends ConsumerStatefulWidget {
  const AllMemosScreen({super.key});

  @override
  ConsumerState<AllMemosScreen> createState() => _AllMemosScreenState();
}

class _AllMemosScreenState extends ConsumerState<AllMemosScreen> {
  String _sortBy = 'updated'; // 'updated', 'created', 'title'

  @override
  Widget build(BuildContext context) {
    final memosAsync = ref.watch(memosStreamProvider);
    final currentFilter = ref.watch(memoFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentFilter.isActive
              ? '${currentFilter.displayName} 메모'
              : '전체 메모',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black87),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'updated',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'updated' ? Icons.check : Icons.update,
                      size: 20,
                      color: const Color(0xFF8B3A3A),
                    ),
                    const SizedBox(width: 8),
                    const Text('수정일순'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'created',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'created' ? Icons.check : Icons.add_circle_outline,
                      size: 20,
                      color: const Color(0xFF8B3A3A),
                    ),
                    const SizedBox(width: 8),
                    const Text('생성일순'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'title' ? Icons.check : Icons.sort_by_alpha,
                      size: 20,
                      color: const Color(0xFF8B3A3A),
                    ),
                    const SizedBox(width: 8),
                    const Text('제목순'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 상태 표시
          if (currentFilter.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFFFF5F5),
              child: Row(
                children: [
                  Icon(
                    currentFilter.type == FilterType.folder
                        ? Icons.folder_outlined
                        : Icons.tag,
                    size: 18,
                    color: const Color(0xFF8B3A3A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${currentFilter.displayName} 필터 적용 중',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B3A3A),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(memoFilterProvider.notifier).clearFilter();
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF8B3A3A),
                    ),
                    label: const Text(
                      '해제',
                      style: TextStyle(color: Color(0xFF8B3A3A)),
                    ),
                  ),
                ],
              ),
            ),

          // 메모 목록
          Expanded(
            child: memosAsync.when(
              data: (memos) {
                if (memos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentFilter.isActive
                              ? '이 필터에 해당하는 메모가 없습니다'
                              : '아직 작성된 메모가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!currentFilter.isActive)
                          Text(
                            '+ 버튼을 눌러 첫 메모를 작성해보세요!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // 정렬
                final sortedMemos = _sortMemos(memos);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(memosStreamProvider);
                  },
                  color: const Color(0xFF8B4444),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 메모 개수
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          '총 ${sortedMemos.length}개',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // 메모 리스트
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sortedMemos.length,
                          itemBuilder: (context, index) {
                            final memo = sortedMemos[index];
                            return _buildMemoCard(memo);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B4444),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '오류가 발생했습니다',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Memo> _sortMemos(List<Memo> memos) {
    final sorted = List<Memo>.from(memos);

    switch (_sortBy) {
      case 'created':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'title':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'updated':
      default:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return sorted;
  }

  Widget _buildMemoCard(Memo memo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showMemoDetail(memo);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  Expanded(
                    child: Text(
                      memo.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (memo.folderId != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 12,
                            color: Color(0xFF8B3A3A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memo.folderId ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B3A3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // 내용
              if (memo.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  memo.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 태그
              if (memo.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: memo.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B3A3A),
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll([
                      if (memo.tags.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '+${memo.tags.length - 3}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ]),
                ),
              ],

              // 날짜
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(memo.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemoDetail(Memo memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                memo.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 내용
              Text(
                memo.content.isEmpty ? '내용이 없습니다.' : memo.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: memo.content.isEmpty ? Colors.grey : Colors.black87,
                ),
              ),

              // 태그
              if (memo.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  '태그',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: memo.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B3A3A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // 메타 정보
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildMetaInfo('생성', memo.createdAt),
              const SizedBox(height: 4),
              _buildMetaInfo('수정', memo.updatedAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '닫기',
              style: TextStyle(color: Color(0xFF8B3A3A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(String label, DateTime date) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          _formatFullDate(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
