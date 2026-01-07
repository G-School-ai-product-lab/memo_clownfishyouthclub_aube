class Memo {
  final String id;
  final String userId;
  final String title;
  final String content;
  final List<String> tags;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const Memo({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.tags,
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  Memo copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    List<String>? tags,
    String? folderId,
    bool clearFolderId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Memo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
