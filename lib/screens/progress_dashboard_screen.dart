import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/assessment.dart';
import '../models/goal.dart';
import '../constants/enums.dart';

/// 성과추이 대시보드
class ProgressDashboardScreen extends StatefulWidget {
  final Patient patient;

  const ProgressDashboardScreen({
    super.key,
    required this.patient,
  });

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  bool _isLoading = false;
  List<Assessment> _assessments = [];
  List<Goal> _goals = [];
  String _selectedPeriod = '3M'; // 1M, 3M, 6M, 1Y

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Firebase에서 데이터 로드
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _assessments = _createMockAssessments();
      _goals = _createMockGoals();
      _isLoading = false;
    });
  }

  List<Assessment> _createMockAssessments() {
    final now = DateTime.now();
    return [
      // 3개월 전
      Assessment(
        id: 'assessment_001',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        assessmentType: AssessmentType.initial,
        templateId: 'template_aquatic_21items',
        assessmentDate: now.subtract(const Duration(days: 90)),
        scores: [],
        totalScore: 42.0,
        summary: AssessmentSummary(
          strengths: ['호흡 조절'],
          challenges: ['균형', '협응'],
          recommendations: ['균형 훈련 집중'],
        ),
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      // 2개월 전
      Assessment(
        id: 'assessment_002',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        assessmentType: AssessmentType.reassessment,
        templateId: 'template_aquatic_21items',
        assessmentDate: now.subtract(const Duration(days: 60)),
        scores: [],
        totalScore: 48.0,
        summary: AssessmentSummary(
          strengths: ['호흡 조절', '참여도'],
          challenges: ['균형'],
          recommendations: ['균형 훈련 지속'],
        ),
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      // 1개월 전
      Assessment(
        id: 'assessment_003',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        assessmentType: AssessmentType.reassessment,
        templateId: 'template_aquatic_21items',
        assessmentDate: now.subtract(const Duration(days: 30)),
        scores: [],
        totalScore: 52.0,
        summary: AssessmentSummary(
          strengths: ['호흡 조절', '참여도', '협응'],
          challenges: ['균형'],
          recommendations: ['균형 훈련 지속'],
        ),
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // 현재
      Assessment(
        id: 'assessment_004',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        assessmentType: AssessmentType.reassessment,
        templateId: 'template_aquatic_21items',
        assessmentDate: now,
        scores: [],
        totalScore: 58.0,
        summary: AssessmentSummary(
          strengths: ['호흡 조절', '참여도', '협응', '균형 개선'],
          challenges: ['근력'],
          recommendations: ['근력 훈련 추가'],
        ),
        createdAt: now,
      ),
    ];
  }

  List<Goal> _createMockGoals() {
    final now = DateTime.now();
    return [
      Goal(
        id: 'goal_001',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        goalText: '독립적 보행',
        smartCriteria: SmartCriteria(
          specific: '보조 없이 10m 보행',
          measurable: '10m 거리',
          achievable: '가능',
          relevant: '일상생활',
          timeBound: now.add(const Duration(days: 30)),
        ),
        category: GoalCategory.functional,
        priority: GoalPriority.high,
        targetDate: now.add(const Duration(days: 30)),
        status: GoalStatus.inProgress,
        progressPercentage: 75.0,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Goal(
        id: 'goal_002',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        goalText: '균형 잡기',
        smartCriteria: SmartCriteria(
          specific: '한 발로 10초',
          measurable: '10초',
          achievable: '가능',
          relevant: '낙상 예방',
          timeBound: now.add(const Duration(days: 14)),
        ),
        category: GoalCategory.functional,
        priority: GoalPriority.high,
        targetDate: now.add(const Duration(days: 14)),
        status: GoalStatus.achieved,
        progressPercentage: 100.0,
        createdAt: now.subtract(const Duration(days: 42)),
      ),
      Goal(
        id: 'goal_003',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        goalText: '근력 향상',
        smartCriteria: SmartCriteria(
          specific: '상지 근력 Good',
          measurable: 'MMT Good',
          achievable: '가능',
          relevant: '일상 동작',
          timeBound: now.add(const Duration(days: 60)),
        ),
        category: GoalCategory.physical,
        priority: GoalPriority.medium,
        targetDate: now.add(const Duration(days: 60)),
        status: GoalStatus.inProgress,
        progressPercentage: 40.0,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('성과추이 - ${widget.patient.name}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: '기간 선택',
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1M', child: Text('1개월')),
              const PopupMenuItem(value: '3M', child: Text('3개월')),
              const PopupMenuItem(value: '6M', child: Text('6개월')),
              const PopupMenuItem(value: '1Y', child: Text('1년')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 요약 카드
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  // 평가 점수 추이 차트
                  _buildScoreTrendChart(),
                  const SizedBox(height: 24),

                  // 목표 달성률
                  _buildGoalAchievementSection(),
                  const SizedBox(height: 24),

                  // 카테고리별 점수 비교
                  _buildCategoryComparisonChart(),
                  const SizedBox(height: 24),

                  // 최근 변화 요약
                  _buildRecentChanges(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final latestScore = _assessments.isNotEmpty ? _assessments.last.totalScore : 0.0;
    final previousScore = _assessments.length > 1 ? _assessments[_assessments.length - 2].totalScore : latestScore;
    final scoreDiff = latestScore - previousScore;
    final percentDiff = previousScore > 0 ? (scoreDiff / previousScore * 100) : 0.0;

    final achievedGoals = _goals.where((g) => g.status == GoalStatus.achieved).length;
    final totalGoals = _goals.length;
    final achievementRate = totalGoals > 0 ? (achievedGoals / totalGoals * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: '현재 점수',
            value: latestScore.toStringAsFixed(0),
            subtitle: '총점 105점 기준',
            icon: Icons.assessment,
            color: Colors.blue,
            trend: scoreDiff,
            trendText: '${scoreDiff >= 0 ? '+' : ''}${scoreDiff.toStringAsFixed(1)}점 (${percentDiff.toStringAsFixed(1)}%)',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: '목표 달성률',
            value: achievementRate.toStringAsFixed(0),
            subtitle: '$achievedGoals / $totalGoals 목표',
            icon: Icons.flag,
            color: Colors.green,
            trend: achievedGoals > 0 ? 1 : 0,
            trendText: '$achievedGoals개 달성',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double trend,
    required String trendText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trend > 0 ? Icons.trending_up : (trend < 0 ? Icons.trending_down : Icons.trending_flat),
                  size: 16,
                  color: trend > 0 ? Colors.green : (trend < 0 ? Colors.red : Colors.grey),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 11,
                      color: trend > 0 ? Colors.green : (trend < 0 ? Colors.red : Colors.grey),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTrendChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '평가 점수 추이',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _assessments.length) {
                            final date = _assessments[value.toInt()].assessmentDate;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  minX: 0,
                  maxX: (_assessments.length - 1).toDouble(),
                  minY: 0,
                  maxY: 105,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _assessments.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.totalScore);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = _assessments[spot.x.toInt()].assessmentDate;
                          return LineTooltipItem(
                            '${DateFormat('yyyy-MM-dd').format(date)}\n${spot.y.toStringAsFixed(1)}점',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalAchievementSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '목표 달성 현황',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._goals.map((goal) => _buildGoalProgressItem(goal)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressItem(Goal goal) {
    Color statusColor;
    switch (goal.status) {
      case GoalStatus.achieved:
        statusColor = Colors.green;
        break;
      case GoalStatus.inProgress:
        statusColor = Colors.blue;
        break;
      case GoalStatus.revised:
        statusColor = Colors.orange;
        break;
      case GoalStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.goalText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${goal.progressPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonChart() {
    // Mock 카테고리별 점수 데이터
    final categoryScores = {
      '균형': 3.2,
      '호흡': 4.5,
      '근력': 2.8,
      '감각': 3.5,
      '참여': 4.0,
      'ROM': 3.0,
      '협응': 3.3,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '카테고리별 점수 (최신)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final category = categoryScores.keys.elementAt(group.x.toInt());
                        return BarTooltipItem(
                          '$category\n${rod.toY.toStringAsFixed(1)}점',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < categoryScores.length) {
                            final category = categoryScores.keys.elementAt(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  barGroups: categoryScores.entries.map((entry) {
                    final index = categoryScores.keys.toList().indexOf(entry.key);
                    final score = entry.value;
                    Color barColor;
                    if (score >= 4.0) {
                      barColor = Colors.green;
                    } else if (score >= 3.0) {
                      barColor = Colors.blue;
                    } else if (score >= 2.0) {
                      barColor = Colors.orange;
                    } else {
                      barColor = Colors.red;
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: score,
                          color: barColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: [
                _buildLegendItem('우수 (4-5점)', Colors.green),
                _buildLegendItem('양호 (3-4점)', Colors.blue),
                _buildLegendItem('보통 (2-3점)', Colors.orange),
                _buildLegendItem('미흡 (<2점)', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRecentChanges() {
    final changes = [
      {
        'icon': Icons.trending_up,
        'color': Colors.green,
        'title': '균형 능력 향상',
        'description': '한 발 서기 5초 → 10초 달성',
        'date': '2일 전',
      },
      {
        'icon': Icons.flag,
        'color': Colors.blue,
        'title': '목표 달성',
        'description': '"균형 잡기" 목표 100% 완료',
        'date': '5일 전',
      },
      {
        'icon': Icons.show_chart,
        'color': Colors.orange,
        'title': '평가 점수 상승',
        'description': '52점 → 58점 (+6점)',
        'date': '1주일 전',
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '최근 변화',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...changes.map((change) => _buildChangeItem(
                  icon: change['icon'] as IconData,
                  color: change['color'] as Color,
                  title: change['title'] as String,
                  description: change['description'] as String,
                  date: change['date'] as String,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
