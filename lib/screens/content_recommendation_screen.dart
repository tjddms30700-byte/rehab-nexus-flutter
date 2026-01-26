import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/content.dart';
import '../models/assessment.dart';
import '../models/goal.dart';
import '../services/recommendation_engine.dart';
import '../utils/mock_data_provider.dart';
import '../constants/enums.dart';

/// 콘텐츠 추천 화면 (Step 3)
class ContentRecommendationScreen extends StatefulWidget {
  final Patient patient;

  const ContentRecommendationScreen({
    super.key,
    required this.patient,
  });

  @override
  State<ContentRecommendationScreen> createState() =>
      _ContentRecommendationScreenState();
}

class _ContentRecommendationScreenState
    extends State<ContentRecommendationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<RecommendationResult> _recommendations = [];
  Assessment? _latestAssessment;

  // 필터 상태
  ContentType? _selectedType;
  DifficultyLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Mock 데이터 로드
      final assessment = MockDataProvider.createMockAssessment(
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
      );

      final contentPool = MockDataProvider.createMockContents();

      // 활성 목표 (빈 목록으로 시작)
      final activeGoals = <Goal>[];

      // 추천 엔진 실행
      final recommendations = RecommendationEngine.recommendContents(
        patient: widget.patient,
        latestAssessment: assessment,
        activeGoals: activeGoals,
        contentPool: contentPool,
        limit: 20,
      );

      setState(() {
        _latestAssessment = assessment;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '추천 콘텐츠를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  List<RecommendationResult> get _filteredRecommendations {
    var filtered = _recommendations;

    if (_selectedType != null) {
      filtered = filtered
          .where((r) => r.content.type == _selectedType)
          .toList();
    }

    if (_selectedLevel != null) {
      filtered = filtered
          .where((r) => r.content.difficultyLevel == _selectedLevel)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('콘텐츠 추천 - ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildRecommendationView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationView() {
    final filtered = _filteredRecommendations;

    return Column(
      children: [
        // 평가 요약 카드
        if (_latestAssessment != null) _buildAssessmentSummaryCard(),
        
        // 필터 섹션
        _buildFilterSection(),
        
        // 추천 결과
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildRecommendationCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAssessmentSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                '최근 평가 결과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                '총점',
                '${_latestAssessment!.totalScore.toStringAsFixed(0)}점',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '퍼센트',
                '${(_latestAssessment!.totalScore / 105 * 100).toStringAsFixed(0)}%',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '레벨',
                'Level ${_getDifficultyLevelFromScore(_latestAssessment!.totalScore)}',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _getDifficultyLevelFromScore(double score) {
    if (score < 43) return 1;
    if (score < 64) return 2;
    if (score < 85) return 3;
    if (score < 106) return 4;
    return 5;
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '필터',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilter(),
                const SizedBox(width: 8),
                _buildLevelFilter(),
                const SizedBox(width: 8),
                if (_selectedType != null || _selectedLevel != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedLevel = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('초기화'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return PopupMenuButton<ContentType>(
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(_selectedType == null ? '타입' : _getContentTypeName(_selectedType!)),
        backgroundColor: _selectedType != null ? Colors.blue.shade100 : null,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ContentType.aquatic,
          child: Text('수중재활'),
        ),
        const PopupMenuItem(
          value: ContentType.general,
          child: Text('일반재활'),
        ),
        const PopupMenuItem(
          value: ContentType.ot,
          child: Text('작업치료'),
        ),
        const PopupMenuItem(
          value: ContentType.pt,
          child: Text('물리치료'),
        ),
      ],
      onSelected: (type) {
        setState(() {
          _selectedType = type;
        });
      },
    );
  }

  Widget _buildLevelFilter() {
    return PopupMenuButton<DifficultyLevel>(
      child: Chip(
        avatar: const Icon(Icons.trending_up, size: 18),
        label: Text(_selectedLevel == null ? '난이도' : 'Level ${_selectedLevel!.index + 1}'),
        backgroundColor: _selectedLevel != null ? Colors.orange.shade100 : null,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: DifficultyLevel.level1,
          child: Text('Level 1 (가장 쉬움)'),
        ),
        const PopupMenuItem(
          value: DifficultyLevel.level2,
          child: Text('Level 2 (쉬움)'),
        ),
        const PopupMenuItem(
          value: DifficultyLevel.level3,
          child: Text('Level 3 (보통)'),
        ),
        const PopupMenuItem(
          value: DifficultyLevel.level4,
          child: Text('Level 4 (어려움)'),
        ),
        const PopupMenuItem(
          value: DifficultyLevel.level5,
          child: Text('Level 5 (가장 어려움)'),
        ),
      ],
      onSelected: (level) {
        setState(() {
          _selectedLevel = level;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '조건에 맞는 콘텐츠가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedLevel = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('필터 초기화'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationResult result) {
    final content = result.content;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showContentDetail(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 제목 + 점수
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildScoreBadge(result.score),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 메타 정보
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    _getContentTypeName(content.type),
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.trending_up,
                    'Level ${content.difficultyLevel.index + 1}',
                    Colors.orange,
                  ),
                  _buildInfoChip(
                    Icons.timer,
                    '${content.durationMinutes}분',
                    Colors.green,
                  ),
                  if (content.equipment.isNotEmpty)
                    _buildInfoChip(
                      Icons.build,
                      content.equipment.first,
                      Colors.purple,
                    ),
                ],
              ),
              
              if (result.reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.reasons.take(2).map((reason) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $reason',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.warnings.first,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.blue;
    } else if (score >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            '점',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getContentTypeName(ContentType type) {
    switch (type) {
      case ContentType.aquatic:
        return '수중재활';
      case ContentType.general:
        return '일반재활';
      case ContentType.ot:
        return '작업치료';
      case ContentType.pt:
        return '물리치료';
    }
  }

  void _showContentDetail(RecommendationResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _buildDetailSheet(result, scrollController);
        },
      ),
    );
  }

  Widget _buildDetailSheet(RecommendationResult result, ScrollController scrollController) {
    final content = result.content;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // 헤더
          Row(
            children: [
              Expanded(
                child: Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildScoreBadge(result.score),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 설명
          Text(
            content.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          
          const SizedBox(height: 24),
          
          // 기본 정보
          _buildDetailSection(
            '기본 정보',
            Icons.info_outline,
            [
              _buildDetailRow('타입', _getContentTypeName(content.type)),
              _buildDetailRow('난이도', 'Level ${content.difficultyLevel.index + 1}'),
              _buildDetailRow('소요시간', '${content.durationMinutes}분'),
              if (content.equipment.isNotEmpty)
                _buildDetailRow('필요 장비', content.equipment.join(', ')),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 수행 방법
          if (content.instructions.isNotEmpty)
            _buildDetailSection(
              '수행 방법',
              Icons.format_list_numbered,
              [
                Text(
                  content.instructions,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
          
          // 추천 이유
          if (result.reasons.isNotEmpty)
            _buildDetailSection(
              '추천 이유',
              Icons.lightbulb_outline,
              result.reasons.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          
          // 주의사항
          if (content.precautions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection(
              '주의사항',
              Icons.warning_amber,
              content.precautions.map((precaution) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          precaution,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          
          // 경고
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        '경고',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...result.warnings.map((warning) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade900,
                          height: 1.5,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('닫기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('콘텐츠를 세션에 추가했습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('세션에 추가'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
