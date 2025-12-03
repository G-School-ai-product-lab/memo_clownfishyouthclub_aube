import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'features/memo/presentation/screens/memo_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await FirebaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: PamyoApp(),
    ),
  );
}

class PamyoApp extends StatelessWidget {
  const PamyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '파묘',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const MemoListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
