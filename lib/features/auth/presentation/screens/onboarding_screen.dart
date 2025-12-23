import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../memo/domain/entities/folder.dart';
import '../../../memo/presentation/providers/folder_providers.dart';
import '../../../memo/presentation/providers/memo_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<Map<String, String>> _defaultFolders = [
    {'name': '학업', 'icon': '📚', 'color': 'blue'},
    {'name': '업무', 'icon': '💼', 'color': 'orange'},
    {'name': '개인', 'icon': '👤', 'color': 'purple'},
    {'name': '아이디어', 'icon': '💡', 'color': 'yellow'},
    {'name': '할 일', 'icon': '✓', 'color': 'green'},
    {'name': '기타', 'icon': '📌', 'color': 'gray'},
  ];

  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '환영합니다! 👋',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '메모를 시작하기 전에\n사용할 폴더를 선택해주세요',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _defaultFolders.length,
                  itemBuilder: (context, index) {
                    final folder = _defaultFolders[index];
                    final isSelected = _selectedIndices.contains(index);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(index);
                          } else {
                            _selectedIndices.add(index);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              folder['icon']!,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              folder['name']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.deepPurple,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIndices.isEmpty
                      ? null
                      : () => _completeOnboarding(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _selectedIndices.isEmpty
                        ? '최소 1개 이상 선택해주세요'
                        : '시작하기 (${_selectedIndices.length}개 선택됨)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 정보를 찾을 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 선택된 폴더 생성
    final selectedFolders = _selectedIndices.map((index) {
      final folderData = _defaultFolders[index];
      final now = DateTime.now();
      return Folder(
        id: const Uuid().v4(),
        userId: userId,
        name: folderData['name']!,
        icon: folderData['icon']!,
        color: folderData['color']!,
        createdAt: now,
      );
    }).toList();

    try {
      // Firebase에 폴더 저장
      final repository = ref.read(folderRepositoryProvider);
      await repository.createFolders(selectedFolders);

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIndices.length}개의 폴더가 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('폴더 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
