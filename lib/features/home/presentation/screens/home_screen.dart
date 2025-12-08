import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../drawer/presentation/widgets/main_drawer.dart';
import '../../../guide/presentation/providers/guide_providers.dart';
import '../../../guide/presentation/widgets/initial_guide_overlay.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../../memo/presentation/providers/filter_providers.dart';
import '../../../memo/presentation/providers/memo_providers.dart';
import '../../../memo/presentation/screens/all_memos_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/ai_search_screen.dart';
import '../widgets/folder_shortcuts_section.dart';
import '../widgets/recent_memos_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _checkGuideStatus();
  }

  Future<void> _checkGuideStatus() async {
    final shouldShow = await ref.read(shouldShowGuideProvider.future);
    if (mounted) {
      setState(() {
        _showGuide = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final memosAsync = ref.watch(memosStreamProvider);
    final currentFilter = ref.watch(memoFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(memosStreamProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // 상단 바
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black87),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.black87),
                        onPressed: () {
                          // TODO: 알림 화면으로 이동
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: Colors.black87),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // 검색창
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildSearchBar(context),
                    ),
                  ),

                  // 폴더 바로가기 섹션
                  const SliverToBoxAdapter(
                    child: FolderShortcutsSection(),
                  ),

                  // 필터 상태 표시 (필터가 활성화된 경우)
                  if (currentFilter.isActive)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Chip(
                              avatar: Icon(
                                currentFilter.type == FilterType.folder
                                    ? Icons.folder_outlined
                                    : Icons.tag,
                                size: 16,
                                color: const Color(0xFF8B3A3A),
                              ),
                              label: Text(
                                currentFilter.displayName ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8B3A3A),
                                ),
                              ),
                              backgroundColor: const Color(0xFFFFF5F5),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF8B3A3A),
                              ),
                              onDeleted: () {
                                ref.read(memoFilterProvider.notifier).clearFilter();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 최근 메모 섹션
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Row(
                        children: [
                          Text(
                            currentFilter.isActive
                                ? '${currentFilter.displayName} 메모'
                                : '최근 메모',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (!currentFilter.isActive)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AllMemosScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                '전체보기',
                                style: TextStyle(
                                  color: Color(0xFF8B4444),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 메모 리스트
                  memosAsync.when(
                    data: (memos) {
                      if (memos.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_add_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '아직 작성된 메모가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '+ 버튼을 눌러 첫 메모를 작성해보세요!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return RecentMemosSection(memos: memos);
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B4444),
                        ),
                      ),
                    ),
                    error: (error, stack) => SliverFillRemaining(
                      child: Center(
                        child: Text('오류가 발생했습니다: $error'),
                      ),
                    ),
                  ),

                  // 하단 여백 (FAB 공간 확보)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),

          // 플로팅 액션 버튼들
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI 검색 버튼
                FloatingActionButton(
                  heroTag: 'ai_search',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiSearchScreen(),
                      ),
                    );
                    ref.read(guideNotifierProvider.notifier).markNaturalSearchUsed();
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(
                    Icons.send,
                    color: Color(0xFF8B4444),
                  ),
                ),
                const SizedBox(height: 16),
                // 메모 작성 버튼
                FloatingActionButton.large(
                  heroTag: 'create_memo',
                  onPressed: () {
                    _showCreateMemoDialog(context);
                  },
                  backgroundColor: const Color(0xFF8B4444),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // 초기 가이드 오버레이
          if (_showGuide)
            InitialGuideOverlay(
              onDismiss: () {
                setState(() {
                  _showGuide = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiSearchScreen(),
            ),
          );
        },
        decoration: InputDecoration(
          hintText: '메모 검색하기...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF8B4444)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiSearchScreen(),
                ),
              );
              ref.read(guideNotifierProvider.notifier).markNaturalSearchUsed();
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _showCreateMemoDialog(BuildContext context) {
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
              if (titleController.text.trim().isEmpty &&
                  contentController.text.trim().isEmpty) {
                return;
              }

              try {
                final repository = ref.read(memoRepositoryProvider);
                final userId = ref.read(currentUserIdProvider);

                if (userId == null) {
                  throw Exception('사용자 ID가 없습니다');
                }

                final memo = Memo(
                  id: '',
                  userId: userId,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  tags: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await repository.createMemo(memo);

                // 가이드 진행 상태 업데이트
                await ref.read(guideNotifierProvider.notifier).markFirstMemoCreated();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('메모가 작성되었습니다!'),
                      backgroundColor: Color(0xFF8B4444),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('저장 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('저장', style: TextStyle(color: Color(0xFF8B4444))),
          ),
        ],
      ),
    );
  }
}
