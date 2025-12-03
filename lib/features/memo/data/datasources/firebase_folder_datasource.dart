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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FolderModel.fromFirestore(doc)).toList());
  }

  Future<FolderModel?> getFolderById(String id) async {
    final doc = await _firestore.collection('folders').doc(id).get();
    if (!doc.exists) return null;
    return FolderModel.fromFirestore(doc);
  }

  Future<void> createFolder(FolderModel folder) async {
    await _firestore
        .collection('folders')
        .doc(folder.id)
        .set(folder.toFirestore());
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
