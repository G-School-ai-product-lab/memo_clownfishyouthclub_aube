import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../memo/presentation/providers/folder_providers.dart';
import '../../../memo/presentation/providers/tag_providers.dart';
import '../../../memo/presentation/providers/filter_providers.dart';
import '../../../memo/presentation/screens/folder_create_screen.dart';
import '../../../memo/presentation/screens/folder_edit_screen.dart';
import '../../../memo/presentation/screens/tag_create_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'drawer_profile_header.dart';
import 'folder_list_item.dart';
import 'tag_list_item.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final foldersAsync = ref.watch(foldersStreamProvider);
    final tagsAsync = ref.watch(tagsStreamProvider);
    final currentFilter = ref.watch(memoFilterProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 헤더
            DrawerProfileHeader(
              user: user,
              onTap: () {
                AppLogger.d('Profile header tapped');
                Navigator.pop(context); // drawer 닫기

                // 프로필 화면으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      AppLogger.d('Navigating to ProfileScreen');
                      return const ProfileScreen();
                    },
                  ),
                );
              },
            ),

            // 스크롤 가능한 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 나의 폴더 섹션
                    _buildSectionHeaderWithButton(
                      context,
                      ref,
                      '나의 폴더',
                      onAdd: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FolderCreateScreen(),
                          ),
                        ).then((created) {
                          if (created == true) {
                            ref.invalidate(foldersStreamProvider);
                          }
                        });
                      },
                    ),
                    foldersAsync.when(
                      data: (folders) {
                        AppLogger.d('MainDrawer - Folders count: ${folders.length}');
                        for (var folder in folders) {
                          AppLogger.d('  - ${folder.name} (${folder.id})');
                        }

                        if (folders.isEmpty) {
                          return _buildEmptyState('폴더가 없습니다');
                        }

                        return Column(
                          children: folders.map((folder) {
                            final isSelected = currentFilter.type == FilterType.folder &&
                                currentFilter.folderId == folder.id;

                            return FolderListItem(
                              folder: folder,
                              isSelected: isSelected,
                              onTap: () {
                                if (isSelected) {
                                  ref.read(memoFilterProvider.notifier).clearFilter();
                                } else {
                                  ref.read(memoFilterProvider.notifier).setFolderFilter(folder);
                                }
                                Navigator.pop(context);
                              },
                              onLongPress: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FolderEditScreen(folder: folder),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B3A3A),
                            ),
                          ),
                        ),
                      ),
                      error: (error, stack) => _buildErrorState('폴더를 불러올 수 없습니다'),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 16),

                    // 나의 태그 섹션
                    _buildSectionHeaderWithButton(
                      context,
                      ref,
                      '나의 태그',
                      onAdd: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TagCreateScreen(),
                          ),
                        ).then((created) {
                          if (created == true) {
                            ref.invalidate(tagsStreamProvider);
                          }
                        });
                      },
                    ),
                    tagsAsync.when(
                      data: (tags) {
                        AppLogger.d('MainDrawer - Tags count: ${tags.length}');
                        for (var tag in tags) {
                          AppLogger.d('  - ${tag.name} (${tag.id})');
                        }

                        if (tags.isEmpty) {
                          return _buildEmptyState('태그가 없습니다');
                        }

                        return Column(
                          children: tags.map((tag) {
                            final isSelected = currentFilter.type == FilterType.tag &&
                                currentFilter.tagId == tag.id;

                            return TagListItem(
                              tag: tag,
                              isSelected: isSelected,
                              onTap: () {
                                if (isSelected) {
                                  ref.read(memoFilterProvider.notifier).clearFilter();
                                } else {
                                  ref.read(memoFilterProvider.notifier).setTagFilter(tag);
                                }
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B3A3A),
                            ),
                          ),
                        ),
                      ),
                      error: (error, stack) => _buildErrorState('태그를 불러올 수 없습니다'),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSectionHeaderWithButton(
    BuildContext context,
    WidgetRef ref,
    String title, {
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            color: const Color(0xFF8B4444),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.red,
        ),
      ),
    );
  }
}
