import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/memo_model.dart';
import 'memo_datasource.dart';

class FirebaseMemoDataSource implements MemoDataSource {
  final FirebaseFirestore _firestore;

  FirebaseMemoDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _memosCollection =>
      _firestore.collection(AppConstants.memosCollection);

  Future<List<MemoModel>> getMemos(String userId) async {
    try {
      final querySnapshot = await _memosCollection
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MemoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch memos: $e');
    }
  }

  Future<MemoModel?> getMemoById(String memoId) async {
    try {
      final doc = await _memosCollection.doc(memoId).get();
      if (!doc.exists) return null;
      return MemoModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch memo: $e');
    }
  }

  Future<String> createMemo(MemoModel memo) async {
    try {
      final docRef = await _memosCollection.add(memo.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create memo: $e');
    }
  }

  Future<void> updateMemo(MemoModel memo) async {
    try {
      await _memosCollection.doc(memo.id).update(memo.toFirestore());
    } catch (e) {
      throw Exception('Failed to update memo: $e');
    }
  }

  Future<void> deleteMemo(String memoId) async {
    try {
      await _memosCollection.doc(memoId).delete();
    } catch (e) {
      throw Exception('Failed to delete memo: $e');
    }
  }

  Stream<List<MemoModel>> watchMemos(String userId) {
    return _memosCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MemoModel.fromFirestore(doc)).toList());
  }
}
