import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/assessment_templates.dart';
import '../constants/enums.dart';
import '../models/assessment.dart';
import '../models/patient.dart';
import '../models/user.dart';
import '../providers/app_state.dart';
import '../services/assessment_service.dart';

/// Step 2: 21개 항목 평가 입력 화면
/// 
/// 특허 기반 자체 평가도구의 21개 항목을 카테고리별로 입력받습니다.
class AssessmentInputScreen extends StatefulWidget {
  final Patient patient;

  const AssessmentInputScreen({
    super.key,
    required this.patient,
  });

  @override
  State<AssessmentInputScreen> createState() => _AssessmentInputScreenState();
}

class _AssessmentInputScreenState extends State<AssessmentInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final AssessmentService _assessmentService = AssessmentService();

  // 21개 항목별 점수 저장
  final Map<String, int> _scores = {};

  // 카테고리별 메모
  final Map<String, String> _categoryNotes = {};

  // 현재 보고 있는 카테고리
  int _currentCategoryIndex = 0;

  // 카테고리별 항목 그룹화
  Map<String, List<Map<String, dynamic>>> _groupedItems = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _groupItemsByCategory();
  }

  /// 21개 항목을 카테고리별로 그룹화
  void _groupItemsByCategory() {
    for (var item in aquaticAssessment21Items) {
      final category = item['category'] as String;
      if (!_groupedItems.containsKey(category)) {
        _groupedItems[category] = [];
      }
      _groupedItems[category]!.add(item);
    }
  }

  /// 전체 21개 항목 점수 합계 계산 (가중치 적용)
  double _calculateTotalScore() {
    double total = 0.0;
    for (var item in aquaticAssessment21Items) {
      final itemId = item['item_id'] as String;
      final weight = item['weight'] as double;
      final score = _scores[itemId] ?? 0;
      total += score * weight;
    }
    return total;
  }

  /// 평가 완료 여부 체크
  bool _isAssessmentComplete() {
    return _scores.length == aquaticAssessment21Items.length;
  }

  /// 평가 저장
  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAssessmentComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 평가해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // ItemScore 리스트 생성
      final scores = _scores.entries.map((entry) {
        return ItemScore(
          itemId: entry.key,
          score: entry.value,
        );
      }).toList();

      // 총점 계산
      final totalScore = _calculateTotalScore();

      // 강점/약점 자동 분석
      final strengths = <String>[];
      final challenges = <String>[];

      for (var item in aquaticAssessment21Items) {
        final itemId = item['item_id'] as String;
        final question = item['question'] as String;
        final score = _scores[itemId] ?? 0;

        if (score >= 4) {
          strengths.add(question);
        } else if (score <= 2) {
          challenges.add(question);
        }
      }

      // 추천사항 생성
      final recommendations = <String>[
        '총점 ${totalScore.toStringAsFixed(1)}점에 따라 맞춤형 프로그램을 추천합니다.',
        if (challenges.isNotEmpty) '약점 영역에 집중하는 프로그램을 우선 적용하세요.',
        if (strengths.isNotEmpty) '강점 영역을 활용한 점진적 난이도 상승을 고려하세요.',
      ];

      // Assessment 생성
      final assessment = Assessment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: widget.patient.id,
        therapistId: currentUser.id,
        assessmentType: AssessmentType.initial,
        templateId: 'aquatic_21_items',
        assessmentDate: DateTime.now(),
        scores: scores,
        totalScore: totalScore,
        summary: AssessmentSummary(
          strengths: strengths,
          challenges: challenges,
          recommendations: recommendations,
        ),
        nextAssessmentDue: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );

      await _assessmentService.createAssessment(assessment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('평가가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // Step 3 콘텐츠 추천으로 이동
        Navigator.pushReplacementNamed(
          context,
          '/content_recommendation',
          arguments: {
            'patient': widget.patient,
            'assessment': assessment,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _groupedItems.keys.toList();
    final currentCategory = categories[_currentCategoryIndex];
    final currentItems = _groupedItems[currentCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('초기 평가 (21개 항목)'),
        actions: [
          TextButton(
            onPressed: _isAssessmentComplete() ? _saveAssessment : null,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 환자 정보
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.patient.age}세 | ${widget.patient.diagnosis}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 진행률 표시
            LinearProgressIndicator(
              value: _scores.length / aquaticAssessment21Items.length,
              backgroundColor: Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '진행률: ${_scores.length} / ${aquaticAssessment21Items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // 카테고리 탭
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = index == _currentCategoryIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(categoryDisplayNames[category] ?? category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _currentCategoryIndex = index);
                      },
                    ),
                  );
                },
              ),
            ),

            // 평가 항목 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentItems.length,
                itemBuilder: (context, index) {
                  return _buildAssessmentItem(currentItems[index]);
                },
              ),
            ),

            // 카테고리 메모
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: '${categoryDisplayNames[currentCategory]} 메모',
                  border: const OutlineInputBorder(),
                  hintText: '이 영역에 대한 추가 관찰 사항을 입력하세요',
                ),
                maxLines: 2,
                onChanged: (value) {
                  _categoryNotes[currentCategory] = value;
                },
              ),
            ),

            // 네비게이션 버튼
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentCategoryIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentCategoryIndex--);
                        },
                        child: const Text('이전'),
                      ),
                    ),
                  if (_currentCategoryIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentCategoryIndex < categories.length - 1
                          ? () {
                              setState(() => _currentCategoryIndex++);
                            }
                          : _isAssessmentComplete()
                              ? _saveAssessment
                              : null,
                      child: Text(
                        _currentCategoryIndex < categories.length - 1
                            ? '다음'
                            : '평가 완료',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 평가 항목 위젯
  Widget _buildAssessmentItem(Map<String, dynamic> item) {
    final itemId = item['item_id'] as String;
    final question = item['question'] as String;
    final options = item['options'] as List<dynamic>;
    final currentScore = _scores[itemId];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (currentScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(currentScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$currentScore점',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (index) {
                final score = index + 1;
                final isSelected = currentScore == score;
                return ChoiceChip(
                  label: Text('$score'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _scores[itemId] = score;
                    });
                  },
                  selectedColor: _getScoreColor(score),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              currentScore != null && currentScore <= options.length
                  ? options[currentScore - 1] as String
                  : '점수를 선택하세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 점수에 따른 색상 반환
  Color _getScoreColor(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
