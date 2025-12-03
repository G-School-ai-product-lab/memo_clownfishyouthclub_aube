import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/firebase_memo_datasource.dart';
import '../../data/repositories/memo_repository_impl.dart';
import '../../domain/entities/memo.dart';
import '../../domain/repositories/memo_repository.dart';

final memoDataSourceProvider = Provider<FirebaseMemoDataSource>((ref) {
  return FirebaseMemoDataSource();
});

final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  final dataSource = ref.watch(memoDataSourceProvider);
  return MemoRepositoryImpl(dataSource: dataSource);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
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
