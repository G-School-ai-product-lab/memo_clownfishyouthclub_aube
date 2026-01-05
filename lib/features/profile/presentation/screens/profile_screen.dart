import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../drawer/presentation/widgets/main_drawer.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/providers/user_providers.dart';
import '../../../memo/presentation/screens/batch_reclassify_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  // 로그아웃 다이얼로그
  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기
              await _handleLogout();
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFF8B3A3A)),
            ),
          ),
        ],
      ),
    );
  }

  // 로그아웃 처리
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();

      if (!mounted) return;

      // 로그인 화면으로 이동 (authStateProvider가 자동으로 처리)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 탈퇴하기 다이얼로그
  Future<void> _showDeleteAccountDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n\n이 작업은 되돌릴 수 없으며,\n모든 데이터가 삭제됩니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기
              await _handleDeleteAccount();
            },
            child: const Text(
              '탈퇴하기',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 회원 탈퇴 처리
  Future<void> _handleDeleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다');
      }

      // 사용자 계정 삭제
      await user.delete();

      if (!mounted) return;

      // 로그인 화면으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );

      // 탈퇴 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원 탈퇴가 완료되었습니다'),
          backgroundColor: Color(0xFF8B3A3A),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      String errorMessage = '회원 탈퇴 실패: ';

      // Firebase Auth 에러 처리
      if (e.toString().contains('requires-recent-login')) {
        errorMessage += '보안을 위해 다시 로그인이 필요합니다';
      } else {
        errorMessage += e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B3A3A),
              ),
            )
          : SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: userProfileAsync.when(
                    data: (userProfile) {
                      final displayName = userProfile?.getDisplayName() ??
                          currentUser?.displayName ??
                          currentUser?.email?.split('@')[0] ??
                          '사용자';
                      final userId =
                          currentUser?.uid.substring(0, 8) ?? 'unknown';

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 프로필 이미지
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileEditScreen(),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: userProfile?.photoURL != null
                                      ? NetworkImage(userProfile!.photoURL!)
                                      : (currentUser?.photoURL != null
                                          ? NetworkImage(currentUser!.photoURL!)
                                          : null),
                                  child: (userProfile?.photoURL == null &&
                                          currentUser?.photoURL == null)
                                      ? Icon(Icons.person,
                                          size: 60, color: Colors.grey[600])
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B3A3A),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 사용자 이름
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 이메일
                          if (currentUser?.email != null)
                            Text(
                              currentUser!.email!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),

                          const SizedBox(height: 4),

                          // 사용자 ID
                          Text(
                            'ID: $userId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 자기소개
                          if (userProfile?.bio != null &&
                              userProfile!.bio!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userProfile.bio!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 32),

                          // AI 일괄 재분류 버튼
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BatchReclassifyScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.auto_awesome,
                                  color: Colors.white),
                              label: const Text(
                                'AI 메모 일괄 재분류',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4444),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 로그아웃 / 탈퇴하기
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _showLogoutDialog,
                                child: const Text(
                                  '로그아웃',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '|',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _showDeleteAccountDialog,
                                child: const Text(
                                  '탈퇴하기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(
                      color: Color(0xFF8B3A3A),
                    ),
                    error: (error, stack) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                            '프로필을 불러오는 중 오류가 발생했습니다.\n${error.toString()}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
