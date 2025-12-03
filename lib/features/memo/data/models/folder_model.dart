import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  const FolderModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.icon,
    required super.color,
    super.memoCount,
    required super.createdAt,
  });

  factory FolderModel.fromEntity(Folder folder) {
    return FolderModel(
      id: folder.id,
      userId: folder.userId,
      name: folder.name,
      icon: folder.icon,
      color: folder.color,
      memoCount: folder.memoCount,
      createdAt: folder.createdAt,
    );
  }

  factory FolderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FolderModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      icon: data['icon'] as String? ?? '📁',
      color: data['color'] as String? ?? 'blue',
      memoCount: data['memoCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'memoCount': memoCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Folder toEntity() {
    return Folder(
      id: id,
      userId: userId,
      name: name,
      icon: icon,
      color: color,
      memoCount: memoCount,
      createdAt: createdAt,
    );
  }
}
