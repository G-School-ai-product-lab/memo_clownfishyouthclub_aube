import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/utils/app_logger.dart';

/// Firebase Storage 서비스
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// 프로필 이미지 업로드
  ///
  /// [userId] 사용자 ID
  /// [imageFile] 업로드할 이미지 파일
  ///
  /// Returns: 업로드된 이미지의 다운로드 URL
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      AppLogger.i('Uploading profile image for user: $userId');

      // 파일 경로: profile_images/{userId}/profile.jpg
      final fileName = 'profile.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 파일 업로드
      final uploadTask = ref.putFile(imageFile, metadata);

      // 업로드 진행 상황 로깅
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.i('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      final downloadURL = await snapshot.ref.getDownloadURL();

      AppLogger.i('Profile image uploaded successfully: $downloadURL');
      return downloadURL;
    } catch (e, stackTrace) {
      AppLogger.e('Error uploading profile image',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 프로필 이미지 삭제
  ///
  /// [userId] 사용자 ID
  Future<void> deleteProfileImage(String userId) async {
    try {
      AppLogger.i('Deleting profile image for user: $userId');

      final fileName = 'profile.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');

      await ref.delete();

      AppLogger.i('Profile image deleted successfully');
    } catch (e, stackTrace) {
      // 파일이 존재하지 않는 경우 에러 무시
      if (e is FirebaseException && e.code == 'object-not-found') {
        AppLogger.i('Profile image not found, skipping deletion');
        return;
      }

      AppLogger.e('Error deleting profile image',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 이미지 파일 크기 제한 확인 (5MB)
  bool isImageSizeValid(File imageFile) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    final fileSize = imageFile.lengthSync();
    return fileSize <= maxSizeInBytes;
  }

  /// 이미지 확장자 확인
  bool isImageExtensionValid(String fileName) {
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }
}
