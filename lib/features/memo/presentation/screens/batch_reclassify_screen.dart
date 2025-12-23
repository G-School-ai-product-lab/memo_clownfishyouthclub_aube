import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memo.dart';
import '../../domain/entities/folder.dart';
import '../providers/memo_providers.dart';
import '../providers/folder_providers.dart';
import '../providers/tag_providers.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../../core/utils/app_logger.dart';

/// 모든 메모를 AI로 일괄 재분류하는 화면
class BatchReclassifyScreen extends ConsumerStatefulWidget {
  const BatchReclassifyScreen({super.key});

  @override
  ConsumerState<BatchReclassifyScreen> createState() =>
      _BatchReclassifyScreenState();
}

class _BatchReclassifyScreenState extends ConsumerState<BatchReclassifyScreen> {
  bool _isProcessing = false;
  int _totalMemos = 0;
  int _processedMemos = 0;
  int _successCount = 0;
  int _failCount = 0;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _startReclassification() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final aiService = ref.read(aiClassificationServiceProvider);
    if (!aiService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 서비스를 사용할 수 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 일괄 재분류'),
        content: const Text(
          '모든 메모를 AI로 재분석하여 폴더와 태그를 자동으로 할당합니다.\n\n'
          '이 작업은 시간이 걸릴 수 있으며, 기존 폴더와 태그가 변경될 수 있습니다.\n\n'
          '계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4444),
            ),
            child: const Text('시작', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _processedMemos = 0;
      _successCount = 0;
      _failCount = 0;
      _logs.clear();
    });

    try {
      final memosAsync = ref.read(memosStreamProvider);
      if (!memosAsync.hasValue) {
        _addLog('메모 목록을 가져올 수 없습니다');
        return;
      }

      final memos = memosAsync.value!;
      _totalMemos = memos.length;
      _addLog('총 ${_totalMemos}개의 메모를 처리합니다');

      final foldersAsync = ref.read(foldersStreamProvider);
      final folders = foldersAsync.hasValue ? foldersAsync.value! : <Folder>[];
      final folderRepository = ref.read(folderRepositoryProvider);
      final tagRepository = ref.read(tagRepositoryProvider);
      final memoRepository = ref.read(memoRepositoryProvider);

      for (final memo in memos) {
        try {
          _addLog('처리 중: ${memo.title}');

          final result = await aiService.classifyMemo(
            title: memo.title,
            content: memo.content,
            folders: folders,
            userId: userId,
            folderRepository: folderRepository,
            allowNewFolder: true,
          );

          if (!result.hasError) {
            // AI가 생성한 태그를 데이터베이스에 자동 생성
            if (result.tags.isNotEmpty) {
              await ensureTagsExist(
                tagNames: result.tags,
                userId: userId,
                tagRepository: tagRepository,
              );
            }

            // 메모 업데이트
            final updatedMemo = Memo(
              id: memo.id,
              userId: memo.userId,
              title: memo.title,
              content: memo.content,
              tags: result.tags,
              folderId: result.folderId,
              createdAt: memo.createdAt,
              updatedAt: DateTime.now(),
              isPinned: memo.isPinned,
            );

            await memoRepository.updateMemo(updatedMemo);

            _successCount++;
            _addLog('✓ 완료: ${result.newFolderCreated ? "새 폴더 생성 | " : ""}${result.folderId != null ? "폴더 지정 | " : ""}태그: ${result.tags.join(", ")}');

            // 폴더가 새로 생성되었으면 목록 갱신
            if (result.newFolderCreated) {
              ref.invalidate(foldersStreamProvider);
              // 최신 폴더 목록 다시 가져오기
              final updatedFoldersAsync = ref.read(foldersStreamProvider);
              if (updatedFoldersAsync.hasValue) {
                folders.clear();
                folders.addAll(updatedFoldersAsync.value!);
              }
            }
          } else {
            _failCount++;
            _addLog('✗ 실패: ${result.error}');
          }
        } catch (e) {
          _failCount++;
          _addLog('✗ 오류: $e');
          AppLogger.e('메모 재분류 실패', error: e);
        }

        setState(() {
          _processedMemos++;
        });

        // API 제한을 피하기 위해 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _addLog('재분류 완료! 성공: $_successCount, 실패: $_failCount');
      ref.invalidate(memosStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '재분류 완료!\n성공: $_successCount개, 실패: $_failCount개',
            ),
            backgroundColor: const Color(0xFF8B4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _addLog('치명적 오류: $e');
      AppLogger.e('일괄 재분류 실패', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('재분류 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalMemos > 0 ? _processedMemos / _totalMemos : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '메모 일괄 재분류',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isProcessing
              ? null
              : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 설명
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE4B5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF8B4444)),
                      SizedBox(width: 8),
                      Text(
                        'AI 일괄 재분류',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B4444),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '모든 메모를 AI로 재분석하여 폴더와 태그를 자동으로 할당합니다.\n'
                    '• 적절한 폴더가 없으면 새로 생성됩니다\n'
                    '• 태그가 자동으로 생성되고 할당됩니다\n'
                    '• 메모 개수에 따라 시간이 걸릴 수 있습니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 진행 상황
            if (_isProcessing || _processedMemos > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '진행 상황',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '$_processedMemos / $_totalMemos',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B4444),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(
                          label: '성공',
                          value: _successCount,
                          color: Colors.green,
                        ),
                        _StatChip(
                          label: '실패',
                          value: _failCount,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 시작 버튼
            if (!_isProcessing)
              ElevatedButton.icon(
                onPressed: _startReclassification,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  '일괄 재분류 시작',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4444),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            // 로그
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '처리 로그',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 통계 칩 위젯
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
