import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder_model.dart';

class FirebaseFolderDatasource {
  final FirebaseFirestore _firestore;

  FirebaseFolderDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<FolderModel>> getFolders(String userId) {
    return _firestore
        .collection('folders')
        .where('userId', isEqualTo: userId)
        // orderBy를 제거하고 메모리에서 정렬 (인덱스 필요 없음)
        .snapshots()
        .map((snapshot) {
          final folders = snapshot.docs
              .map((doc) => FolderModel.fromFirestore(doc))
              .toList();

          // 메모리에서 createdAt 기준으로 정렬
          folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return folders;
        });
  }

  Future<FolderModel?> getFolderById(String id) async {
    final doc = await _firestore.collection('folders').doc(id).get();
    if (!doc.exists) return null;
    return FolderModel.fromFirestore(doc);
  }

  Future<FolderModel?> getFolderByName(String userId, String name) async {
    final querySnapshot = await _firestore
        .collection('folders')
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return FolderModel.fromFirestore(querySnapshot.docs.first);
  }

  Future<FolderModel> createFolder(FolderModel folder) async {
    // ID가 비어있으면 자동 생성
    final docRef = folder.id.isEmpty
        ? _firestore.collection('folders').doc()
        : _firestore.collection('folders').doc(folder.id);

    final newFolder = FolderModel(
      id: docRef.id,
      userId: folder.userId,
      name: folder.name,
      icon: folder.icon,
      color: folder.color,
      memoCount: folder.memoCount,
      createdAt: folder.createdAt,
    );

    await docRef.set(newFolder.toFirestore());
    return newFolder;
  }

  Future<void> updateFolder(FolderModel folder) async {
    await _firestore
        .collection('folders')
        .doc(folder.id)
        .update(folder.toFirestore());
  }

  Future<void> deleteFolder(String id) async {
    await _firestore.collection('folders').doc(id).delete();
  }

  Future<void> createFolders(List<FolderModel> folders) async {
    final batch = _firestore.batch();
    for (final folder in folders) {
      final docRef = _firestore.collection('folders').doc(folder.id);
      batch.set(docRef, folder.toFirestore());
    }
    await batch.commit();
  }
}
