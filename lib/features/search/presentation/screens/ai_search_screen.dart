import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../../memo/presentation/providers/memo_providers.dart';
import '../../../memo/presentation/screens/memo_view_screen.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  List<Memo> _searchResults = [];
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performAiSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final groqService = ref.read(groqServiceProvider);
      if (groqService == null) {
        setState(() {
          _errorMessage = 'AI 검색 기능을 사용할 수 없습니다. API 키를 확인해주세요.';
          _isSearching = false;
        });
        return;
      }

      // 모든 메모 가져오기
      final memosAsync = ref.read(memosStreamProvider);
      final memos = memosAsync.value ?? [];

      if (memos.isEmpty) {
        setState(() {
          _errorMessage = '검색할 메모가 없습니다.';
          _isSearching = false;
        });
        return;
      }

      // AI로 자연어 쿼리를 검색 키워드로 변환
      final searchKeywords = await _extractSearchKeywords(query, groqService);

      // 키워드를 기반으로 메모 필터링 및 점수 계산
      final scoredMemos = <MapEntry<Memo, double>>[];

      for (final memo in memos) {
        final score = _calculateRelevanceScore(memo, query, searchKeywords);
        if (score > 0) {
          scoredMemos.add(MapEntry(memo, score));
        }
      }

      // 점수 순으로 정렬
      scoredMemos.sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _searchResults = scoredMemos.map((e) => e.key).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '검색 중 오류가 발생했습니다: $e';
        _isSearching = false;
      });
    }
  }

  Future<List<String>> _extractSearchKeywords(
    String query,
    dynamic groqService,
  ) async {
    try {
      final keywords = await groqService.generateTags(
        memoTitle: query,
        memoContent: '',
        maxTags: 5,
      );

      if (keywords.isEmpty) return [query];

      return keywords;
    } catch (e) {
      return [query];
    }
  }

  double _calculateRelevanceScore(
    Memo memo,
    String originalQuery,
    List<String> keywords,
  ) {
    double score = 0.0;
    final lowerQuery = originalQuery.toLowerCase();
    final lowerTitle = memo.title.toLowerCase();
    final lowerContent = memo.content.toLowerCase();

    // 원본 쿼리 완전 일치 (높은 점수)
    if (lowerTitle.contains(lowerQuery)) score += 10.0;
    if (lowerContent.contains(lowerQuery)) score += 5.0;

    // 키워드 일치
    for (final keyword in keywords) {
      final lowerKeyword = keyword.toLowerCase();
      if (lowerTitle.contains(lowerKeyword)) score += 3.0;
      if (lowerContent.contains(lowerKeyword)) score += 1.5;

      // 태그 일치
      for (final tag in memo.tags) {
        if (tag.toLowerCase().contains(lowerKeyword)) score += 2.0;
      }
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 자연어 검색',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B3A3A).withOpacity(0.2)),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '어떤 메모를 찾으시나요? (예: 지난주 회의 내용)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.psychology, color: Colors.grey[400]),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF8B4444)),
                    onPressed: () => _performAiSearch(_controller.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _performAiSearch,
              ),
            ),
          ),

          // 검색 안내
          if (!_isSearching && _searchResults.isEmpty && _errorMessage == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI 자연어 검색',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '자연스러운 문장으로 메모를 검색해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildExampleChip('지난주 회의록'),
                    const SizedBox(height: 8),
                    _buildExampleChip('중요한 할 일'),
                    const SizedBox(height: 8),
                    _buildExampleChip('프로젝트 관련 메모'),
                  ],
                ),
              ),
            ),

          // 로딩
          if (_isSearching)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF8B4444),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'AI가 메모를 검색하고 있습니다...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // 에러 메시지
          if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 검색 결과
          if (!_isSearching && _searchResults.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      '검색 결과 ${_searchResults.length}개',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final memo = _searchResults[index];
                        return _buildMemoCard(memo);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return InkWell(
      onTap: () {
        _controller.text = text;
        _performAiSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B3A3A).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search,
              size: 16,
              color: Color(0xFF8B3A3A),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8B3A3A),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoCard(Memo memo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoViewScreen(memo: memo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (memo.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  memo.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (memo.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: memo.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B3A3A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(memo.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
