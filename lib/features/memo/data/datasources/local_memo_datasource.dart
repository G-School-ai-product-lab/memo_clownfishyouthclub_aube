import 'dart:async';
import '../models/memo_model.dart';
import 'memo_datasource.dart';

class LocalMemoDataSource implements MemoDataSource {
  final List<MemoModel> _memos = [];
  int _idCounter = 0;

  @override
  Future<List<MemoModel>> getMemos(String userId) async {
    return _memos
        .where((memo) => memo.userId == userId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<MemoModel?> getMemoById(String memoId) async {
    try {
      return _memos.firstWhere((memo) => memo.id == memoId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> createMemo(MemoModel memo) async {
    final id = 'memo_${_idCounter++}';
    final now = DateTime.now();
    final newMemo = MemoModel(
      id: id,
      userId: memo.userId,
      title: memo.title,
      content: memo.content,
      folderId: memo.folderId,
      tags: memo.tags,
      createdAt: now,
      updatedAt: now,
      isPinned: memo.isPinned,
    );
    _memos.add(newMemo);
    return id;
  }

  @override
  Future<void> updateMemo(MemoModel memo) async {
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index == -1) {
      throw Exception('Memo not found: ${memo.id}');
    }

    final updatedMemo = MemoModel(
      id: memo.id,
      userId: memo.userId,
      title: memo.title,
      content: memo.content,
      folderId: memo.folderId,
      tags: memo.tags,
      createdAt: memo.createdAt,
      updatedAt: DateTime.now(),
      isPinned: memo.isPinned,
    );

    _memos[index] = updatedMemo;
  }

  @override
  Future<void> deleteMemo(String memoId) async {
    _memos.removeWhere((memo) => memo.id == memoId);
  }

  @override
  Stream<List<MemoModel>> watchMemos(String userId) async* {
    while (true) {
      yield await getMemos(userId);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
