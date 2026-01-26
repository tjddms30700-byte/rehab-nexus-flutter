import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/assessment.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';
import '../services/assessment_service.dart';
import '../providers/app_state.dart';

/// 평가 입력 화면 - 간단 버전 (21개 항목)
class AssessmentScreen extends StatefulWidget {
  final Patient patient;

  const AssessmentScreen({
    super.key,
    required this.patient,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final Map<String, double> _scores = {};
  final _notesController = TextEditingController();
  final _assessmentService = AssessmentService();
  bool _isSaving = false;

  // 21개 평가 항목
  final List<Map<String, dynamic>> _assessmentItems = [
    // 균형 (3)
    {'id': 'balance_01', 'category': '균형', 'question': '물속에서 서 있는 자세 유지'},
    {'id': 'balance_02', 'category': '균형', 'question': '물속 보행 시 균형 유지'},
    {'id': 'balance_03', 'category': '균형', 'question': '한 발로 서기 (물속)'},
    
    // 호흡 (2)
    {'id': 'breathing_01', 'category': '호흡', 'question': '호흡 조절 능력'},
    {'id': 'breathing_02', 'category': '호흡', 'question': '수중 호흡 적응'},
    
    // 근력 (3)
    {'id': 'strength_01', 'category': '근력', 'question': '상지 근력 (팔)'},
    {'id': 'strength_02', 'category': '근력', 'question': '하지 근력 (다리)'},
    {'id': 'strength_03', 'category': '근력', 'question': '몸통 근력 (코어)'},
    
    // 감각통합 (3)
    {'id': 'sensory_01', 'category': '감각', 'question': '촉각 반응'},
    {'id': 'sensory_02', 'category': '감각', 'question': '수온 적응'},
    {'id': 'sensory_03', 'category': '감각', 'question': '물 흐름 감각'},
    
    // 참여도 (2)
    {'id': 'participation_01', 'category': '참여', 'question': '활동 참여 의지'},
    {'id': 'participation_02', 'category': '참여', 'question': '치료사 협조'},
    
    // ROM (2)
    {'id': 'rom_01', 'category': 'ROM', 'question': '상지 관절 가동범위'},
    {'id': 'rom_02', 'category': 'ROM', 'question': '하지 관절 가동범위'},
    
    // 협응 (2)
    {'id': 'coordination_01', 'category': '협응', 'question': '양손 협응력'},
    {'id': 'coordination_02', 'category': '협응', 'question': '팔-다리 협응력'},
    
    // 수중 특화 (2)
    {'id': 'aquatic_01', 'category': '수중', 'question': '물에 대한 두려움'},
    {'id': 'aquatic_02', 'category': '수중', 'question': '부력 이용 능력'},
    
    // 안전 (1)
    {'id': 'safety_01', 'category': '안전', 'question': '안전 인식'},
    
    // 지구력 (1)
    {'id': 'endurance_01', 'category': '지구력', 'question': '활동 지속 능력'},
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🟢 AssessmentScreen: initState called');
      print('   Patient: ${widget.patient.name}');
    }
    // 초기 점수 설정
    for (var item in _assessmentItems) {
      _scores[item['id']] = 3.0;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalScore {
    return _scores.values.fold(0, (sum, score) => sum + score.toInt());
  }

  int get _percentage {
    return ((_totalScore / 105) * 100).toInt();
  }

  String get _recommendedLevel {
    if (_totalScore < 43) return 'Level 1';
    if (_totalScore < 64) return 'Level 2';
    if (_totalScore < 85) return 'Level 3';
    if (_totalScore < 106) return 'Level 4';
    return 'Level 5';
  }

  Future<void> _saveAssessment() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
      }

      // 강점, 약점, 권장사항 자동 생성
      final strengths = <String>[];
      final challenges = <String>[];
      final recommendations = <String>[];

      // 점수 분석
      _scores.forEach((id, score) {
        final item = _assessmentItems.firstWhere((item) => item['id'] == id);
        final category = item['category'] as String;
        
        if (score >= 4.0) {
          strengths.add('$category 우수 (${score.toInt()}점)');
        } else if (score <= 2.0) {
          challenges.add('$category 보완 필요 (${score.toInt()}점)');
          recommendations.add('$category 집중 훈련 권장');
        }
      });

      // 기본 권장사항
      if (recommendations.isEmpty) {
        recommendations.add('현재 수준 유지 및 강화');
      }
      recommendations.add('$_recommendedLevel 콘텐츠 활용 권장');

      // scores를 List<ItemScore>로 변환
      final itemScores = _scores.entries
          .map((entry) => ItemScore(
                itemId: entry.key,
                score: entry.value,
              ))
          .toList();

      // Assessment 객체 생성
      final assessment = Assessment(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        patientId: widget.patient.id,
        therapistId: currentUser.id,
        assessmentType: AssessmentType.initial,
        templateId: 'template_aquatic_21items',
        assessmentDate: DateTime.now(),
        scores: itemScores,
        totalScore: _totalScore.toDouble(),
        summary: AssessmentSummary(
          strengths: strengths.take(3).toList(),
          challenges: challenges.take(3).toList(),
          recommendations: recommendations.take(3).toList(),
        ),
        createdAt: DateTime.now(),
      );

      // Firebase에 저장
      try {
        final assessmentId = await _assessmentService.createAssessment(assessment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 평가가 저장되었습니다!\n총점: $_totalScore점\nID: $assessmentId'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, assessment);
        }
      } catch (firebaseError) {
        // Firebase 오류 시 로컬에만 저장 (Mock)
        if (kDebugMode) {
          print('Firebase Error: $firebaseError');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 평가가 입력되었습니다!\n총점: $_totalScore점 ($_percentage%)\n💡 Firebase 연결 시 실제 저장됩니다'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, assessment);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Assessment Save Error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 평가 저장 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔵 AssessmentScreen: build called');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.name} - 평가'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          // 환자 정보 및 점수 요약
          Container(
            color: const Color(0x1A0077BE), // AppTheme.primary with 10% opacity
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.patient.age}세 · ${widget.patient.gender == "M" ? "남" : "여"}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_totalScore / 105점',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text('$_percentage%'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '추천 난이도: $_recommendedLevel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 평가 항목 목록
          ListView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assessmentItems.length,
            itemBuilder: (context, index) {
                final item = _assessmentItems[index];
                final itemId = item['id'] as String;
                final score = _scores[itemId] ?? 3.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x3300C9A7), // AppTheme.secondary with 20% opacity
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['category'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['question'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: score,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: score.toInt().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _scores[itemId] = value;
                                  });
                                },
                              ),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${score.toInt()}점',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1점', style: TextStyle(fontSize: 12)),
                            Text('매우 낮음', style: TextStyle(fontSize: 12)),
                            Text('보통', style: TextStyle(fontSize: 12)),
                            Text('우수', style: TextStyle(fontSize: 12)),
                            Text('5점', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 저장 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '평가 저장',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
