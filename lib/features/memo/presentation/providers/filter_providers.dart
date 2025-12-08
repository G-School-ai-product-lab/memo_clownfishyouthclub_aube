import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/tag.dart';

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
