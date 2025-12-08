import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../datasources/firebase_tag_datasource.dart';
import '../models/tag_model.dart';

class TagRepositoryImpl implements TagRepository {
  final FirebaseTagDatasource _datasource;

  TagRepositoryImpl(this._datasource);

  @override
  Stream<List<Tag>> getTags(String userId) {
    return _datasource
        .getTags(userId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Tag?> getTagById(String userId, String tagId) async {
    final model = await _datasource.getTagById(userId, tagId);
    return model?.toEntity();
  }

  @override
  Future<Tag?> getTagByName(String userId, String name) async {
    final model = await _datasource.getTagByName(userId, name);
    return model?.toEntity();
  }

  @override
  Future<void> createTag(Tag tag) async {
    final model = TagModel.fromEntity(tag);
    await _datasource.createTag(model);
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final model = TagModel.fromEntity(tag);
    await _datasource.updateTag(model);
  }

  @override
  Future<void> deleteTag(String userId, String tagId) async {
    await _datasource.deleteTag(userId, tagId);
  }

  @override
  Future<void> incrementMemoCount(String userId, String tagId) async {
    await _datasource.incrementMemoCount(userId, tagId);
  }

  @override
  Future<void> decrementMemoCount(String userId, String tagId) async {
    await _datasource.decrementMemoCount(userId, tagId);
  }

  @override
  Future<void> createTags(List<Tag> tags) async {
    final models = tags.map((tag) => TagModel.fromEntity(tag)).toList();
    await _datasource.createTags(models);
  }
}
