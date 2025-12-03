import '../entities/memo.dart';

abstract class MemoRepository {
  Future<List<Memo>> getMemos(String userId);
  Future<Memo?> getMemoById(String memoId);
  Future<String> createMemo(Memo memo);
  Future<void> updateMemo(Memo memo);
  Future<void> deleteMemo(String memoId);
  Stream<List<Memo>> watchMemos(String userId);
}
