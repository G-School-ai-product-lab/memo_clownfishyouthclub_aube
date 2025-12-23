import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/memo/presentation/providers/memo_providers.dart';
import 'features/memo/presentation/providers/folder_providers.dart';

void main() async {
  print('=== APP STARTING ===');
  WidgetsFlutterBinding.ensureInitialized();
  print('WidgetsFlutterBinding initialized');

  try {
    // Firebase 초기화
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Firebase initialization error: $e');
    print('Stack trace: $stackTrace');
  }

  print('Running app...');
  runApp(
    const ProviderScope(
      child: PamyoApp(),
    ),
  );
  print('runApp called');
}

class PamyoApp extends ConsumerWidget {
  const PamyoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('PamyoApp build called');
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: '파묘',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B3A3A),
        ),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) {
          print('Auth state: user = ${user?.uid ?? "null"}');
          // 로그인 상태에 따라 화면 분기
          if (user != null) {
            // 로그인된 사용자의 경우 온보딩 완료 여부 확인
            final foldersAsync = ref.watch(foldersStreamProvider);

            return foldersAsync.when(
              data: (folders) {
                print('Folders count: ${folders.length}');
                // 폴더가 없으면 온보딩으로, 있으면 홈으로
                if (folders.isEmpty) {
                  return const OnboardingScreen();
                } else {
                  return const HomeScreen();
                }
              },
              loading: () {
                print('Folders loading');
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B4444),
                    ),
                  ),
                );
              },
              error: (error, stack) {
                print('Folders error: $error');
                // 에러 발생 시에도 온보딩으로
                return const OnboardingScreen();
              },
            );
          } else {
            return const LoginScreen();
          }
        },
        loading: () {
          print('Auth state: loading');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B4444),
              ),
            ),
          );
        },
        error: (error, stack) {
          print('Auth state error: $error');
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
