import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/memo.dart';

class MemoModel extends Memo {
  const MemoModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.content,
    required super.tags,
    super.folderId,
    required super.createdAt,
    required super.updatedAt,
    super.isPinned,
  });

  factory MemoModel.fromEntity(Memo memo) {
    return MemoModel(
      id: memo.id,
      userId: memo.userId,
      title: memo.title,
      content: memo.content,
      tags: memo.tags,
      folderId: memo.folderId,
      createdAt: memo.createdAt,
      updatedAt: memo.updatedAt,
      isPinned: memo.isPinned,
    );
  }

  factory MemoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String? ?? '',
      content: data['content'] as String,
      tags: List<String>.from(data['tags'] as List? ?? []),
      folderId: data['folderId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'tags': tags,
      'folderId': folderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
    };
  }

  Memo toEntity() {
    return Memo(
      id: id,
      userId: userId,
      title: title,
      content: content,
      tags: tags,
      folderId: folderId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
    );
  }
}
