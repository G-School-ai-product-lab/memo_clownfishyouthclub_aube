import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_clownfishyouthclub_aube/features/memo/data/datasources/firebase_memo_datasource.dart';
import 'package:memo_clownfishyouthclub_aube/features/memo/data/models/memo_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseMemoDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseMemoDataSource(firestore: fakeFirestore);
  });

  group('FirebaseMemoDataSource', () {
    const testUserId = 'test-user-id';
    final testDate = DateTime(2024, 1, 1);

    MemoModel createTestMemo({
      String id = 'test-memo-id',
      String userId = testUserId,
      String title = 'Test Memo',
      String content = 'Test Content',
      List<String> tags = const ['test', 'memo'],
      String? folderId,
      bool isPinned = false,
    }) {
      return MemoModel(
        id: id,
        userId: userId,
        title: title,
        content: content,
        tags: tags,
        folderId: folderId,
        createdAt: testDate,
        updatedAt: testDate,
        isPinned: isPinned,
      );
    }

    group('createMemo', () {
      test('메모를 성공적으로 생성해야 한다', () async {
        // Arrange
        final memo = createTestMemo();

        // Act
        final memoId = await dataSource.createMemo(memo);

        // Assert
        expect(memoId, isNotEmpty);
        final doc = await fakeFirestore
            .collection('memos')
            .doc(memoId)
            .get();
        expect(doc.exists, true);
        expect(doc.data()?['title'], 'Test Memo');
        expect(doc.data()?['content'], 'Test Content');
        expect(doc.data()?['userId'], testUserId);
      });

      test('태그가 포함된 메모를 생성해야 한다', () async {
        // Arrange
        final memo = createTestMemo(tags: ['tag1', 'tag2', 'tag3']);

        // Act
        final memoId = await dataSource.createMemo(memo);

        // Assert
        final doc = await fakeFirestore
            .collection('memos')
            .doc(memoId)
            .get();
        expect(doc.data()?['tags'], ['tag1', 'tag2', 'tag3']);
      });

      test('폴더 ID가 포함된 메모를 생성해야 한다', () async {
        // Arrange
        final memo = createTestMemo(folderId: 'test-folder-id');

        // Act
        final memoId = await dataSource.createMemo(memo);

        // Assert
        final doc = await fakeFirestore
            .collection('memos')
            .doc(memoId)
            .get();
        expect(doc.data()?['folderId'], 'test-folder-id');
      });
    });

    group('getMemos', () {
      test('사용자의 모든 메모를 가져와야 한다', () async {
        // Arrange
        await dataSource.createMemo(createTestMemo(id: 'memo1'));
        await dataSource.createMemo(createTestMemo(id: 'memo2'));
        await dataSource.createMemo(
          createTestMemo(id: 'memo3', userId: 'other-user'),
        );

        // Act
        final memos = await dataSource.getMemos(testUserId);

        // Assert
        expect(memos.length, 2);
        expect(memos.every((m) => m.userId == testUserId), true);
      });

      test('메모가 updatedAt 기준 내림차순으로 정렬되어야 한다', () async {
        // Arrange
        final memo1 = createTestMemo(id: 'memo1')
            .toEntity()
            .copyWith(updatedAt: DateTime(2024, 1, 1));
        final memo2 = createTestMemo(id: 'memo2')
            .toEntity()
            .copyWith(updatedAt: DateTime(2024, 1, 3));
        final memo3 = createTestMemo(id: 'memo3')
            .toEntity()
            .copyWith(updatedAt: DateTime(2024, 1, 2));

        await dataSource.createMemo(MemoModel.fromEntity(memo1));
        await dataSource.createMemo(MemoModel.fromEntity(memo2));
        await dataSource.createMemo(MemoModel.fromEntity(memo3));

        // Act
        final memos = await dataSource.getMemos(testUserId);

        // Assert
        expect(memos.length, 3);
        expect(memos[0].updatedAt, DateTime(2024, 1, 3)); // 가장 최근
        expect(memos[1].updatedAt, DateTime(2024, 1, 2));
        expect(memos[2].updatedAt, DateTime(2024, 1, 1)); // 가장 오래됨
      });

      test('메모가 없으면 빈 리스트를 반환해야 한다', () async {
        // Act
        final memos = await dataSource.getMemos(testUserId);

        // Assert
        expect(memos, isEmpty);
      });
    });

    group('getMemoById', () {
      test('ID로 메모를 가져와야 한다', () async {
        // Arrange
        final memoId = await dataSource.createMemo(
          createTestMemo(title: 'Specific Memo'),
        );

        // Act
        final memo = await dataSource.getMemoById(memoId);

        // Assert
        expect(memo, isNotNull);
        expect(memo?.id, memoId);
        expect(memo?.title, 'Specific Memo');
      });

      test('존재하지 않는 ID면 null을 반환해야 한다', () async {
        // Act
        final memo = await dataSource.getMemoById('non-existent-id');

        // Assert
        expect(memo, isNull);
      });
    });

    group('updateMemo', () {
      test('메모를 성공적으로 업데이트해야 한다', () async {
        // Arrange
        final memoId = await dataSource.createMemo(
          createTestMemo(title: 'Old Title'),
        );

        final updatedMemo = createTestMemo(
          id: memoId,
          title: 'New Title',
          content: 'New Content',
        );

        // Act
        await dataSource.updateMemo(updatedMemo);

        // Assert
        final memo = await dataSource.getMemoById(memoId);
        expect(memo?.title, 'New Title');
        expect(memo?.content, 'New Content');
      });

      test('태그를 업데이트해야 한다', () async {
        // Arrange
        final memoId = await dataSource.createMemo(
          createTestMemo(tags: ['old']),
        );

        final updatedMemo = createTestMemo(
          id: memoId,
          tags: ['new1', 'new2'],
        );

        // Act
        await dataSource.updateMemo(updatedMemo);

        // Assert
        final memo = await dataSource.getMemoById(memoId);
        expect(memo?.tags, ['new1', 'new2']);
      });

      test('폴더 ID를 업데이트해야 한다', () async {
        // Arrange
        final memoId = await dataSource.createMemo(
          createTestMemo(folderId: 'old-folder'),
        );

        final updatedMemo = createTestMemo(
          id: memoId,
          folderId: 'new-folder',
        );

        // Act
        await dataSource.updateMemo(updatedMemo);

        // Assert
        final memo = await dataSource.getMemoById(memoId);
        expect(memo?.folderId, 'new-folder');
      });
    });

    group('deleteMemo', () {
      test('메모를 성공적으로 삭제해야 한다', () async {
        // Arrange
        final memoId = await dataSource.createMemo(createTestMemo());

        // Act
        await dataSource.deleteMemo(memoId);

        // Assert
        final memo = await dataSource.getMemoById(memoId);
        expect(memo, isNull);
      });

      test('삭제 후 메모 목록에 포함되지 않아야 한다', () async {
        // Arrange
        final memoId1 = await dataSource.createMemo(createTestMemo(id: 'memo1'));
        final memoId2 = await dataSource.createMemo(createTestMemo(id: 'memo2'));

        // Act
        await dataSource.deleteMemo(memoId1);

        // Assert
        final memos = await dataSource.getMemos(testUserId);
        expect(memos.length, 1);
        expect(memos.first.id, memoId2);
      });
    });

    group('watchMemos', () {
      test('메모 스트림이 초기 데이터를 방출해야 한다', () async {
        // Arrange
        await dataSource.createMemo(createTestMemo());

        // Act & Assert
        await expectLater(
          dataSource.watchMemos(testUserId),
          emits(isA<List<MemoModel>>().having((list) => list.length, 'length', 1)),
        );
      });

      test('빈 스트림은 빈 리스트를 방출해야 한다', () async {
        // Act & Assert
        await expectLater(
          dataSource.watchMemos(testUserId).first,
          completion(isEmpty),
        );
      });

      test('스트림이 올바른 타입을 반환해야 한다', () async {
        // Arrange
        await dataSource.createMemo(createTestMemo());

        // Act
        final stream = dataSource.watchMemos(testUserId);

        // Assert
        expect(stream, isA<Stream<List<MemoModel>>>());
      });
    });
  });
}
