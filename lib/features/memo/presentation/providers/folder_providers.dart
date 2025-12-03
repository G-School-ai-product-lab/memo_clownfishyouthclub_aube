import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_folder_datasource.dart';
import '../../data/repositories/folder_repository_impl.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import 'memo_providers.dart';

final folderDatasourceProvider = Provider<FirebaseFolderDatasource>((ref) {
  return FirebaseFolderDatasource();
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final datasource = ref.watch(folderDatasourceProvider);
  return FolderRepositoryImpl(datasource);
});

final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final repository = ref.watch(folderRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  return repository.getFolders(userId);
});
