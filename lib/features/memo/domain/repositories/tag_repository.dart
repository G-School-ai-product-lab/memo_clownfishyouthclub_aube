import '../entities/tag.dart';

abstract class TagRepository {
  Stream<List<Tag>> getTags(String userId);
  Future<Tag?> getTagById(String userId, String tagId);
  Future<Tag?> getTagByName(String userId, String name);
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String userId, String tagId);
  Future<void> incrementMemoCount(String userId, String tagId);
  Future<void> decrementMemoCount(String userId, String tagId);
  Future<void> createTags(List<Tag> tags);
}
