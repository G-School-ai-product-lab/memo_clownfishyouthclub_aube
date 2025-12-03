import '../../domain/entities/memo.dart';
import '../../domain/repositories/memo_repository.dart';
import '../datasources/firebase_memo_datasource.dart';
import '../models/memo_model.dart';

class MemoRepositoryImpl implements MemoRepository {
  final FirebaseMemoDataSource _dataSource;

  MemoRepositoryImpl({required FirebaseMemoDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<Memo>> getMemos(String userId) async {
    final memoModels = await _dataSource.getMemos(userId);
    return memoModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Memo?> getMemoById(String memoId) async {
    final memoModel = await _dataSource.getMemoById(memoId);
    return memoModel?.toEntity();
  }

  @override
  Future<String> createMemo(Memo memo) async {
    final memoModel = MemoModel.fromEntity(memo);
    return await _dataSource.createMemo(memoModel);
  }

  @override
  Future<void> updateMemo(Memo memo) async {
    final memoModel = MemoModel.fromEntity(memo);
    await _dataSource.updateMemo(memoModel);
  }

  @override
  Future<void> deleteMemo(String memoId) async {
    await _dataSource.deleteMemo(memoId);
  }

  @override
  Stream<List<Memo>> watchMemos(String userId) {
    return _dataSource
        .watchMemos(userId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }
}
