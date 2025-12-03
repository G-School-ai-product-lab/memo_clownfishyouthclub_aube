class Folder {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final int memoCount;
  final DateTime createdAt;

  const Folder({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.memoCount = 0,
    required this.createdAt,
  });

  Folder copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    int? memoCount,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      memoCount: memoCount ?? this.memoCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
