import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/services/storage_service.dart';

/// UserRepository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

/// StorageService Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Firebase Auth 사용자 스트림
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 현재 로그인한 사용자 ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// 현재 로그인한 사용자의 프로필 (스트림)
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserProfile(userId);
});

/// 특정 사용자의 프로필 조회 (일회성)
final userProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserProfileOnce(userId);
});

/// 사용자 존재 여부 확인
final userExistsProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.userExists(userId);
});
