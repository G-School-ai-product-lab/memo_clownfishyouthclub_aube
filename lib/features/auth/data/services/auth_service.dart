import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../repositories/user_repository_impl.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepositoryImpl();

  // 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 사용자 프로필 생성 또는 업데이트
  Future<void> _createOrUpdateUserProfile(User user) async {
    try {
      final userExists = await _userRepository.userExists(user.uid);

      if (!userExists) {
        // 신규 사용자 - 프로필 생성
        final userProfile = UserProfile(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _userRepository.createUserProfile(userProfile);
        AppLogger.i('New user profile created: ${user.uid}');
      } else {
        // 기존 사용자 - 마지막 로그인 시간 업데이트
        await _userRepository.updateLastLoginAt(user.uid);
        AppLogger.i('User last login updated: ${user.uid}');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error creating/updating user profile',
          error: e, stackTrace: stackTrace);
      // 프로필 생성 실패해도 로그인은 계속 진행
    }
  }

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In 프로세스 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // 사용자가 로그인을 취소한 경우
      if (googleUser == null) {
        return null;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증 자격증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      // 사용자 프로필 생성 또는 업데이트
      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw '이미 다른 로그인 방법으로 가입된 계정입니다.';
        case 'invalid-credential':
          throw '인증 정보가 올바르지 않습니다.';
        case 'operation-not-allowed':
          throw 'Google 로그인이 활성화되지 않았습니다.';
        case 'user-disabled':
          throw '비활성화된 계정입니다.';
        case 'user-not-found':
          throw '사용자를 찾을 수 없습니다.';
        case 'wrong-password':
          throw '비밀번호가 올바르지 않습니다.';
        case 'invalid-verification-code':
          throw '인증 코드가 올바르지 않습니다.';
        case 'invalid-verification-id':
          throw '인증 ID가 올바르지 않습니다.';
        default:
          throw '로그인 중 오류가 발생했습니다: ${e.message}';
      }
    } catch (e) {
      throw '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw '로그아웃 중 오류가 발생했습니다.';
    }
  }

  // 이메일/비밀번호 로그인 (향후 구현)
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw '사용자를 찾을 수 없습니다.';
        case 'wrong-password':
          throw '비밀번호가 올바르지 않습니다.';
        case 'invalid-email':
          throw '이메일 형식이 올바르지 않습니다.';
        case 'user-disabled':
          throw '비활성화된 계정입니다.';
        default:
          throw '로그인 중 오류가 발생했습니다: ${e.message}';
      }
    }
  }

  // 회원가입 (향후 구현)
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 프로필 생성
      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw '이미 사용 중인 이메일입니다.';
        case 'invalid-email':
          throw '이메일 형식이 올바르지 않습니다.';
        case 'weak-password':
          throw '비밀번호가 너무 약합니다.';
        case 'operation-not-allowed':
          throw '이메일/비밀번호 로그인이 활성화되지 않았습니다.';
        default:
          throw '회원가입 중 오류가 발생했습니다: ${e.message}';
      }
    }
  }
}
