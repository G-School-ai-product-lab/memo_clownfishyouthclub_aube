class Tag {
  final String id;
  final String userId;
  final String name;
  final String color;
  final int memoCount;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.memoCount = 0,
    required this.createdAt,
  });

  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    int? memoCount,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      memoCount: memoCount ?? this.memoCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
