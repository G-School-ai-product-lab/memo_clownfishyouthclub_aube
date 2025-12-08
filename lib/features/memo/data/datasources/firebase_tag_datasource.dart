import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tag_model.dart';

class FirebaseTagDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getCollectionPath(String userId) => 'users/$userId/tags';

  Stream<List<TagModel>> getTags(String userId) {
    return _firestore
        .collection(_getCollectionPath(userId))
        .orderBy('memoCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TagModel.fromFirestore(doc))
            .toList());
  }

  Future<TagModel?> getTagById(String userId, String tagId) async {
    final doc = await _firestore
        .collection(_getCollectionPath(userId))
        .doc(tagId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return TagModel.fromFirestore(doc);
  }

  Future<TagModel?> getTagByName(String userId, String name) async {
    final querySnapshot = await _firestore
        .collection(_getCollectionPath(userId))
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return TagModel.fromFirestore(querySnapshot.docs.first);
  }

  Future<void> createTag(TagModel tag) async {
    final docRef = _firestore.collection(_getCollectionPath(tag.userId)).doc();
    final tagWithId = TagModel(
      id: docRef.id,
      userId: tag.userId,
      name: tag.name,
      color: tag.color,
      memoCount: tag.memoCount,
      createdAt: tag.createdAt,
    );
    await docRef.set(tagWithId.toFirestore());
  }

  Future<void> updateTag(TagModel tag) async {
    await _firestore
        .collection(_getCollectionPath(tag.userId))
        .doc(tag.id)
        .update(tag.toFirestore());
  }

  Future<void> deleteTag(String userId, String tagId) async {
    await _firestore
        .collection(_getCollectionPath(userId))
        .doc(tagId)
        .delete();
  }

  Future<void> incrementMemoCount(String userId, String tagId) async {
    await _firestore
        .collection(_getCollectionPath(userId))
        .doc(tagId)
        .update({'memoCount': FieldValue.increment(1)});
  }

  Future<void> decrementMemoCount(String userId, String tagId) async {
    await _firestore
        .collection(_getCollectionPath(userId))
        .doc(tagId)
        .update({'memoCount': FieldValue.increment(-1)});
  }

  Future<void> createTags(List<TagModel> tags) async {
    if (tags.isEmpty) return;

    final batch = _firestore.batch();
    final userId = tags.first.userId;

    for (final tag in tags) {
      final docRef =
          _firestore.collection(_getCollectionPath(userId)).doc();
      final tagWithId = TagModel(
        id: docRef.id,
        userId: tag.userId,
        name: tag.name,
        color: tag.color,
        memoCount: tag.memoCount,
        createdAt: tag.createdAt,
      );
      batch.set(docRef, tagWithId.toFirestore());
    }

    await batch.commit();
  }
}
