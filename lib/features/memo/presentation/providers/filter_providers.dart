import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/tag.dart';
import '../../domain/entities/memo.dart';
import 'memo_providers.dart';

enum FilterType { none, folder, tag }

class MemoFilter {
  final FilterType type;
  final String? folderId;
  final String? tagId;
  final String? displayName;

  const MemoFilter({
    this.type = FilterType.none,
    this.folderId,
    this.tagId,
    this.displayName,
  });

  const MemoFilter.none()
      : type = FilterType.none,
        folderId = null,
        tagId = null,
        displayName = null;

  MemoFilter.folder(Folder folder)
      : type = FilterType.folder,
        folderId = folder.id,
        tagId = null,
        displayName = folder.name;

  MemoFilter.tag(Tag tag)
      : type = FilterType.tag,
        folderId = null,
        tagId = tag.id,
        displayName = tag.name;

  bool get isActive => type != FilterType.none;

  MemoFilter copyWith({
    FilterType? type,
    String? folderId,
    String? tagId,
    String? displayName,
  }) {
    return MemoFilter(
      type: type ?? this.type,
      folderId: folderId ?? this.folderId,
      tagId: tagId ?? this.tagId,
      displayName: displayName ?? this.displayName,
    );
  }
}

class MemoFilterNotifier extends StateNotifier<MemoFilter> {
  MemoFilterNotifier() : super(const MemoFilter.none());

  void setFolderFilter(Folder folder) {
    state = MemoFilter.folder(folder);
  }

  void setTagFilter(Tag tag) {
    state = MemoFilter.tag(tag);
  }

  void clearFilter() {
    state = const MemoFilter.none();
  }
}

final memoFilterProvider =
    StateNotifierProvider<MemoFilterNotifier, MemoFilter>((ref) {
  return MemoFilterNotifier();
});

/// 필터링된 메모 리스트를 제공하는 provider
final filteredMemosProvider = StreamProvider<List<Memo>>((ref) {
  final memosAsync = ref.watch(memosStreamProvider);
  final filter = ref.watch(memoFilterProvider);

  return memosAsync.when(
    data: (memos) {
      // 필터가 없으면 모든 메모 반환
      if (!filter.isActive) {
        return Stream.value(memos);
      }

      // 폴더 필터 적용
      if (filter.type == FilterType.folder && filter.folderId != null) {
        final filtered = memos.where((memo) => memo.folderId == filter.folderId).toList();
        return Stream.value(filtered);
      }

      // 태그 필터 적용 (태그 이름으로 필터링)
      if (filter.type == FilterType.tag && filter.displayName != null) {
        final filtered = memos.where((memo) => memo.tags.contains(filter.displayName)).toList();
        return Stream.value(filtered);
      }

      return Stream.value(memos);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
