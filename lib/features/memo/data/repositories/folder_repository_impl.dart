import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/firebase_folder_datasource.dart';
import '../models/folder_model.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FirebaseFolderDatasource _datasource;

  FolderRepositoryImpl(this._datasource);

  @override
  Stream<List<Folder>> getFolders(String userId) {
    return _datasource
        .getFolders(userId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Folder?> getFolderById(String id) async {
    final model = await _datasource.getFolderById(id);
    return model?.toEntity();
  }

  @override
  Future<Folder?> getFolderByName(String userId, String name) async {
    final model = await _datasource.getFolderByName(userId, name);
    return model?.toEntity();
  }

  @override
  Future<Folder> createFolder(Folder folder) async {
    final model = FolderModel.fromEntity(folder);
    final createdModel = await _datasource.createFolder(model);
    return createdModel.toEntity();
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final model = FolderModel.fromEntity(folder);
    await _datasource.updateFolder(model);
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _datasource.deleteFolder(id);
  }

  @override
  Future<void> createFolders(List<Folder> folders) async {
    final models = folders.map((folder) => FolderModel.fromEntity(folder)).toList();
    await _datasource.createFolders(models);
  }
}
