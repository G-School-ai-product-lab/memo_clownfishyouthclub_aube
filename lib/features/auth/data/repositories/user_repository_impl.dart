import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_profile_model.dart';

/// UserRepository 구현체 (Firestore)
class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// users 컬렉션 참조
  CollectionReference get _usersCollection => _firestore.collection('users');

  @override
  Stream<UserProfile?> getUserProfile(String userId) {
    try {
      return _usersCollection.doc(userId).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return UserProfileModel.fromFirestore(snapshot).toEntity();
      });
    } catch (e, stackTrace) {
      AppLogger.e('Error getting user profile stream',
          error: e, stackTrace: stackTrace);
      return Stream.value(null);
    }
  }

  @override
  Future<UserProfile?> getUserProfileOnce(String userId) async {
    try {
      final snapshot = await _usersCollection.doc(userId).get();
      if (!snapshot.exists) {
        return null;
      }
      return UserProfileModel.fromFirestore(snapshot).toEntity();
    } catch (e, stackTrace) {
      AppLogger.e('Error getting user profile',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      await _usersCollection.doc(profile.uid).set(model.toFirestore());
      AppLogger.i('User profile created: ${profile.uid}');
    } catch (e, stackTrace) {
      AppLogger.e('Error creating user profile',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final model = UserProfileModel.fromEntity(
        profile.copyWith(updatedAt: DateTime.now()),
      );
      await _usersCollection.doc(profile.uid).update(model.toFirestore());
      AppLogger.i('User profile updated: ${profile.uid}');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating user profile',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _usersCollection.doc(userId).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Display name updated: $userId');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating display name',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateBio(String userId, String bio) async {
    try {
      await _usersCollection.doc(userId).update({
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Bio updated: $userId');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating bio', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updatePhotoURL(String userId, String photoURL) async {
    try {
      await _usersCollection.doc(userId).update({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Photo URL updated: $userId');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating photo URL',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateLastLoginAt(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Last login updated: $userId');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating last login',
          error: e, stackTrace: stackTrace);
      // 로그인 시간 업데이트 실패는 무시
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      AppLogger.i('User profile deleted: $userId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting user profile',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> userExists(String userId) async {
    try {
      final snapshot = await _usersCollection.doc(userId).get();
      return snapshot.exists;
    } catch (e, stackTrace) {
      AppLogger.e('Error checking user existence',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
