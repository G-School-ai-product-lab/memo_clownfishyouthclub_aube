import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_tag_datasource.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import 'memo_providers.dart';

final tagDatasourceProvider = Provider<FirebaseTagDatasource>((ref) {
  return FirebaseTagDatasource();
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final datasource = ref.watch(tagDatasourceProvider);
  return TagRepositoryImpl(datasource);
});

final tagsStreamProvider = StreamProvider<List<Tag>>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  return repository.getTags(userId);
});
