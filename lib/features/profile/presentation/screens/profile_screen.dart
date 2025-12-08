import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../drawer/presentation/widgets/main_drawer.dart';
import '../../../auth/data/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

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

  String _getUserDisplayName() {
    if (_currentUser == null) return '사용자';

    // Google 로그인인 경우 displayName 사용
    if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }

    // 이메일에서 사용자명 추출
    if (_currentUser!.email != null) {
      return _currentUser!.email!.split('@')[0];
    }

    return '사용자';
  }

  String _getUserId() {
    if (_currentUser == null) return 'unknown';

    // UID의 앞 8자리만 표시
    return _currentUser!.uid.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 프로필 이미지
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 사용자 이름
                      Text(
                        _getUserDisplayName(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 사용자 ID
                      Text(
                        'ID: ${_getUserId()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 48),

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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  ),
                ),
              ),
            ),
    );
  }
}
