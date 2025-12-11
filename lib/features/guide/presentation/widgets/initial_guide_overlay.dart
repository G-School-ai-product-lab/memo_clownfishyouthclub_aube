import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/guide_providers.dart';

class InitialGuideOverlay extends ConsumerWidget {
  final VoidCallback onDismiss;

  const InitialGuideOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(guideNotifierProvider);

    return GestureDetector(
      onTap: () async {
        await ref.read(guideNotifierProvider.notifier).dismissGuide();
        onDismiss();
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 내부 탭은 무시
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Row(
                    children: [
                      const Text(
                        '✨ 파묘 시작하기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '(${progress.completedCount}/${progress.totalCount} 완료)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 체크리스트
                  _buildCheckItem(
                    '첫 메모 작성하기',
                    progress.firstMemoCreated,
                  ),
                  const SizedBox(height: 16),
                  _buildCheckItem(
                    'AI 자동 분류 확인하기',
                    progress.aiClassificationChecked,
                  ),
                  const SizedBox(height: 16),
                  _buildCheckItem(
                    '자연어로 검색해보기',
                    progress.naturalSearchUsed,
                  ),
                  const SizedBox(height: 16),
                  _buildCheckItem(
                    '링크 자동 요약 경험해보기',
                    progress.linkSummaryChecked,
                  ),

                  const SizedBox(height: 24),

                  // 하단 링크
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: 가이드 상세 페이지로 이동
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '파묘 더 알아보기',
                            style: TextStyle(
                              color: Color(0xFF8B4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Color(0xFF8B4444),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isChecked) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_circle : Icons.circle_outlined,
          color: isChecked ? const Color(0xFF8B4444) : Colors.grey[400],
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isChecked ? Colors.black87 : Colors.grey[600],
              fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
              decoration: isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}
