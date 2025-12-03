import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tag.dart';

class TagModel extends Tag {
  const TagModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.color,
    super.memoCount,
    required super.createdAt,
  });

  factory TagModel.fromEntity(Tag tag) {
    return TagModel(
      id: tag.id,
      userId: tag.userId,
      name: tag.name,
      color: tag.color,
      memoCount: tag.memoCount,
      createdAt: tag.createdAt,
    );
  }

  factory TagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TagModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      color: data['color'] as String? ?? 'purple',
      memoCount: data['memoCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'color': color,
      'memoCount': memoCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Tag toEntity() {
    return Tag(
      id: id,
      userId: userId,
      name: name,
      color: color,
      memoCount: memoCount,
      createdAt: createdAt,
    );
  }
}
