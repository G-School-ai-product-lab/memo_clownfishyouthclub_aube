import '../entities/user_profile.dart';

/// 사용자 프로필 Repository 인터페이스
abstract class UserRepository {
  /// 사용자 프로필 조회 (스트림)
  Stream<UserProfile?> getUserProfile(String userId);

  /// 사용자 프로필 조회 (일회성)
  Future<UserProfile?> getUserProfileOnce(String userId);

  /// 사용자 프로필 생성
  Future<void> createUserProfile(UserProfile profile);

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile(UserProfile profile);

  /// 사용자 닉네임 업데이트
  Future<void> updateDisplayName(String userId, String displayName);

  /// 사용자 자기소개 업데이트
  Future<void> updateBio(String userId, String bio);

  /// 프로필 사진 URL 업데이트
  Future<void> updatePhotoURL(String userId, String photoURL);

  /// 마지막 로그인 시간 업데이트
  Future<void> updateLastLoginAt(String userId);

  /// 사용자 프로필 삭제
  Future<void> deleteUserProfile(String userId);

  /// 사용자 존재 여부 확인
  Future<bool> userExists(String userId);
}
