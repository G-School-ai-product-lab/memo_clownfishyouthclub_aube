import '../entities/folder.dart';

abstract class FolderRepository {
  Stream<List<Folder>> getFolders(String userId);
  Future<Folder?> getFolderById(String id);
  Future<Folder?> getFolderByName(String userId, String name);
  Future<Folder> createFolder(Folder folder);
  Future<void> updateFolder(Folder folder);
  Future<void> deleteFolder(String id);
  Future<void> createFolders(List<Folder> folders);
}
