import 'package:equatable/equatable.dart';

/// 사용자 프로필 엔티티
class UserProfile extends Equatable {
  /// 사용자 ID (Firebase Auth UID)
  final String uid;

  /// 이메일
  final String email;

  /// 닉네임 (사용자가 설정한 표시 이름)
  final String? displayName;

  /// 프로필 이미지 URL
  final String? photoURL;

  /// 자기소개
  final String? bio;

  /// 계정 생성일
  final DateTime createdAt;

  /// 프로필 수정일
  final DateTime? updatedAt;

  /// 마지막 로그인 시간
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  /// displayName이 없으면 이메일의 로컬 부분 반환
  String getDisplayName() {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email.split('@')[0];
  }

  /// 프로필이 완성되었는지 확인 (닉네임과 프로필 사진이 모두 있는지)
  bool get isComplete => displayName != null && photoURL != null;

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoURL,
        bio,
        createdAt,
        updatedAt,
        lastLoginAt,
      ];

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
