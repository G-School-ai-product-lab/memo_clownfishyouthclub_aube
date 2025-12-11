import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/memo_model.dart';
import 'memo_datasource.dart';

class FirebaseMemoDataSource implements MemoDataSource {
  final FirebaseFirestore _firestore;

  FirebaseMemoDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _memosCollection =>
      _firestore.collection(AppConstants.memosCollection);

  @override
  Future<List<MemoModel>> getMemos(String userId) async {
    try {
      AppLogger.d('Fetching memos for user: $userId');
      final querySnapshot = await _memosCollection
          .where('userId', isEqualTo: userId)
          .get();

      final memos = querySnapshot.docs
          .map((doc) => MemoModel.fromFirestore(doc))
          .toList();

      // 메모리에서 updatedAt 기준으로 정렬
      memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      AppLogger.d('Fetched ${memos.length} memos for user: $userId');
      return memos;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to fetch memos', error: e, stackTrace: stackTrace);
      throw Exception('Failed to fetch memos: $e');
    }
  }

  @override
  Future<MemoModel?> getMemoById(String memoId) async {
    try {
      AppLogger.d('Fetching memo by id: $memoId');
      final doc = await _memosCollection.doc(memoId).get();
      if (!doc.exists) {
        AppLogger.d('Memo not found: $memoId');
        return null;
      }
      return MemoModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to fetch memo', error: e, stackTrace: stackTrace);
      throw Exception('Failed to fetch memo: $e');
    }
  }

  @override
  Future<String> createMemo(MemoModel memo) async {
    try {
      AppLogger.d('Creating memo: ${memo.title}');
      final docRef = await _memosCollection.add(memo.toFirestore());
      AppLogger.i('Memo created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to create memo', error: e, stackTrace: stackTrace);
      throw Exception('Failed to create memo: $e');
    }
  }

  @override
  Future<void> updateMemo(MemoModel memo) async {
    try {
      AppLogger.d('Updating memo: ${memo.id}');
      await _memosCollection.doc(memo.id).update(memo.toFirestore());
      AppLogger.i('Memo updated successfully: ${memo.id}');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update memo', error: e, stackTrace: stackTrace);
      throw Exception('Failed to update memo: $e');
    }
  }

  @override
  Future<void> deleteMemo(String memoId) async {
    try {
      AppLogger.d('Deleting memo: $memoId');
      await _memosCollection.doc(memoId).delete();
      AppLogger.i('Memo deleted successfully: $memoId');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete memo', error: e, stackTrace: stackTrace);
      throw Exception('Failed to delete memo: $e');
    }
  }

  @override
  Stream<List<MemoModel>> watchMemos(String userId) {
    AppLogger.d('Starting watchMemos stream for user: $userId');
    return _memosCollection
        .where('userId', isEqualTo: userId)
        // orderBy를 제거하고 메모리에서 정렬 (인덱스 필요 없음)
        .snapshots()
        .map((snapshot) {
          AppLogger.d('Snapshot received - docs count: ${snapshot.docs.length}');
          final memos = snapshot.docs.map((doc) {
            final memo = MemoModel.fromFirestore(doc);
            AppLogger.d('Converted memo: id=${memo.id}, title=${memo.title}');
            return memo;
          }).toList();

          // 메모리에서 updatedAt 기준으로 정렬
          memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          AppLogger.d('Total memos after sorting: ${memos.length}');
          return memos;
        });
  }
}
