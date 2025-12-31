import '../../domain/entities/memo.dart';
import '../../domain/entities/tag.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/memo_repository.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/memo_datasource.dart';
import '../models/memo_model.dart';

class MemoRepositoryImpl implements MemoRepository {
  final MemoDataSource _dataSource;
  final TagRepository _tagRepository;
  final FolderRepository _folderRepository;

  MemoRepositoryImpl({
    required MemoDataSource dataSource,
    required TagRepository tagRepository,
    required FolderRepository folderRepository,
  })  : _dataSource = dataSource,
        _tagRepository = tagRepository,
        _folderRepository = folderRepository;

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
    final memoId = await _dataSource.createMemo(memoModel);

    // 태그 카운트 증가 (비동기 처리를 기다림)
    for (final tagName in memo.tags) {
      // 재시도 로직 추가: 새로 생성된 태그가 아직 조회되지 않을 수 있음
      Tag? tag;
      for (int i = 0; i < 3; i++) {
        tag = await _tagRepository.getTagByName(memo.userId, tagName);
        if (tag != null) break;
        if (i < 2) await Future.delayed(const Duration(milliseconds: 100));
      }

      if (tag != null) {
        await _tagRepository.incrementMemoCount(memo.userId, tag.id);
      }
    }

    // 폴더 카운트 증가 (비동기 처리를 기다림)
    if (memo.folderId != null) {
      // 재시도 로직 추가: 새로 생성된 폴더가 아직 조회되지 않을 수 있음
      Folder? folder;
      for (int i = 0; i < 3; i++) {
        folder = await _folderRepository.getFolderById(memo.folderId!);
        if (folder != null) break;
        if (i < 2) await Future.delayed(const Duration(milliseconds: 100));
      }

      if (folder != null) {
        final updatedFolder = folder.copyWith(memoCount: folder.memoCount + 1);
        await _folderRepository.updateFolder(updatedFolder);
      }
    }

    return memoId;
  }

  @override
  Future<void> updateMemo(Memo memo) async {
    // 기존 메모 정보 가져오기
    final oldMemo = await getMemoById(memo.id);

    final memoModel = MemoModel.fromEntity(memo);
    await _dataSource.updateMemo(memoModel);

    if (oldMemo != null) {
      // 태그 변경사항 처리
      final oldTags = oldMemo.tags.toSet();
      final newTags = memo.tags.toSet();

      // 제거된 태그의 카운트 감소
      final removedTags = oldTags.difference(newTags);
      for (final tagName in removedTags) {
        final tag = await _tagRepository.getTagByName(memo.userId, tagName);
        if (tag != null) {
          await _tagRepository.decrementMemoCount(memo.userId, tag.id);
        }
      }

      // 추가된 태그의 카운트 증가
      final addedTags = newTags.difference(oldTags);
      for (final tagName in addedTags) {
        // 재시도 로직: 새로 생성된 태그가 아직 조회되지 않을 수 있음
        Tag? tag;
        for (int i = 0; i < 3; i++) {
          tag = await _tagRepository.getTagByName(memo.userId, tagName);
          if (tag != null) break;
          if (i < 2) await Future.delayed(const Duration(milliseconds: 100));
        }

        if (tag != null) {
          await _tagRepository.incrementMemoCount(memo.userId, tag.id);
        }
      }

      // 폴더 변경사항 처리
      if (oldMemo.folderId != memo.folderId) {
        // 이전 폴더 카운트 감소
        if (oldMemo.folderId != null) {
          final oldFolder = await _folderRepository.getFolderById(oldMemo.folderId!);
          if (oldFolder != null) {
            final updatedFolder = oldFolder.copyWith(
              memoCount: oldFolder.memoCount > 0 ? oldFolder.memoCount - 1 : 0,
            );
            await _folderRepository.updateFolder(updatedFolder);
          }
        }

        // 새 폴더 카운트 증가
        if (memo.folderId != null) {
          // 재시도 로직: 새로 생성된 폴더가 아직 조회되지 않을 수 있음
          Folder? newFolder;
          for (int i = 0; i < 3; i++) {
            newFolder = await _folderRepository.getFolderById(memo.folderId!);
            if (newFolder != null) break;
            if (i < 2) await Future.delayed(const Duration(milliseconds: 100));
          }

          if (newFolder != null) {
            final updatedFolder = newFolder.copyWith(memoCount: newFolder.memoCount + 1);
            await _folderRepository.updateFolder(updatedFolder);
          }
        }
      }
    }
  }

  @override
  Future<void> deleteMemo(String memoId) async {
    // 메모 정보를 먼저 가져오기 (삭제 전에)
    final memo = await getMemoById(memoId);

    await _dataSource.deleteMemo(memoId);

    if (memo != null) {
      // 태그 카운트 감소
      for (final tagName in memo.tags) {
        final tag = await _tagRepository.getTagByName(memo.userId, tagName);
        if (tag != null) {
          await _tagRepository.decrementMemoCount(memo.userId, tag.id);
        }
      }

      // 폴더 카운트 감소
      if (memo.folderId != null) {
        final folder = await _folderRepository.getFolderById(memo.folderId!);
        if (folder != null) {
          final updatedFolder = folder.copyWith(
            memoCount: folder.memoCount > 0 ? folder.memoCount - 1 : 0,
          );
          await _folderRepository.updateFolder(updatedFolder);
        }
      }
    }
  }

  @override
  Stream<List<Memo>> watchMemos(String userId) {
    return _dataSource
        .watchMemos(userId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }
}
