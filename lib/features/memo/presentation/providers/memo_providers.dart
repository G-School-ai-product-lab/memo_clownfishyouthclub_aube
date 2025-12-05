import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_memo_datasource.dart';
import '../../data/repositories/memo_repository_impl.dart';
import '../../domain/entities/memo.dart';
import '../../domain/repositories/memo_repository.dart';

// Firebase 기반 DataSource
final memoDataSourceProvider = Provider<FirebaseMemoDataSource>((ref) {
  return FirebaseMemoDataSource();
});

final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  final dataSource = ref.watch(memoDataSourceProvider);
  return MemoRepositoryImpl(dataSource: dataSource);
});

// 임시 사용자 ID (Firebase 인증 대신)
final currentUserIdProvider = Provider<String?>((ref) {
  return 'demo_user_001';
});

final memosStreamProvider = StreamProvider<List<Memo>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(memoRepositoryProvider);
  return repository.watchMemos(userId);
});

final memoListProvider = FutureProvider<List<Memo>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getMemos(userId);
});
