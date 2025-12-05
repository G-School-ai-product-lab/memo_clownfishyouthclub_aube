import '../models/memo_model.dart';

/// 메모 데이터 소스 인터페이스
/// LocalMemoDataSource와 FirebaseMemoDataSource가 이 인터페이스를 구현
abstract class MemoDataSource {
  Future<List<MemoModel>> getMemos(String userId);
  Future<MemoModel?> getMemoById(String memoId);
  Future<String> createMemo(MemoModel memo);
  Future<void> updateMemo(MemoModel memo);
  Future<void> deleteMemo(String memoId);
  Stream<List<MemoModel>> watchMemos(String userId);
}
