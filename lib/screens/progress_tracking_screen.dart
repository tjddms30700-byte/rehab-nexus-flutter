import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/patient.dart';
import '../constants/enums.dart';
import 'dart:math' as math;

/// 성과 추이 화면 (차트 및 보고서 포함)
class ProgressTrackingScreen extends StatefulWidget {
  final Patient patient;

  const ProgressTrackingScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assessmentHistory = [];
  List<Map<String, dynamic>> _sessionHistory = [];
  List<Map<String, dynamic>> _goalProgress = [];
  String? _errorMessage;
  
  // 보고서 생성 상태
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 평가 이력 조회
      final assessmentsSnapshot = await FirebaseFirestore.instance
          .collection('assessments')
          .where('patient_id', isEqualTo: widget.patient.id)
          .orderBy('assessment_date', descending: true)
          .limit(10)
          .get();

      _assessmentHistory = assessmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'date': (data['assessment_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'type': data['assessment_type'] ?? 'GENERAL',
          'score': data['total_score'] ?? 0,
        };
      }).toList();

      // 2. 세션 이력 조회
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('patient_id', isEqualTo: widget.patient.id)
          .orderBy('session_date', descending: true)
          .limit(20)
          .get();

      _sessionHistory = sessionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'date': (data['session_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'type': data['session_type'] ?? 'THERAPY',
          'duration': data['duration_minutes'] ?? 60,
          'notes': data['notes'] ?? '',
        };
      }).toList();

      // 3. 목표 진행도 조회
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('goals')
          .where('patient_id', isEqualTo: widget.patient.id)
          .where('status', whereIn: ['IN_PROGRESS', 'ACHIEVED'])
          .orderBy('created_at', descending: true)
          .get();

      _goalProgress = goalsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['goal_text'] ?? '목표 없음',
          'progress': data['progress_percentage'] ?? 0,
          'status': data['status'] ?? 'IN_PROGRESS',
          'target_date': (data['target_date'] as Timestamp?)?.toDate(),
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '데이터를 불러오는데 실패했습니다: $e';
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final report = await showDialog<String>(
        context: context,
        builder: (context) => _ReportGeneratorDialog(
          patient: widget.patient,
          assessmentHistory: _assessmentHistory,
          sessionHistory: _sessionHistory,
          goalProgress: _goalProgress,
        ),
      );

      if (report != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보고서가 생성되었습니다')),
        );
      }
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.name} - 성과 추이'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgressData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: _isGeneratingReport ? null : _generateReport,
            tooltip: '보고서 생성',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 환자 정보 카드
                      _buildPatientInfoCard(),
                      const SizedBox(height: 24),

                      // 목표 달성률 차트
                      _buildSectionTitle('목표 달성률', Icons.track_changes),
                      const SizedBox(height: 12),
                      _buildGoalProgressChart(),
                      const SizedBox(height: 24),

                      // 평가 점수 추이 차트
                      _buildSectionTitle('평가 점수 추이', Icons.trending_up),
                      const SizedBox(height: 12),
                      _buildAssessmentChart(),
                      const SizedBox(height: 24),

                      // 세션 빈도 차트
                      _buildSectionTitle('월별 세션 빈도', Icons.calendar_month),
                      const SizedBox(height: 12),
                      _buildSessionFrequencyChart(),
                      const SizedBox(height: 24),

                      // 목표 진행도
                      _buildSectionTitle('목표 진행도', Icons.flag),
                      const SizedBox(height: 12),
                      _buildGoalProgressSection(),
                      const SizedBox(height: 24),

                      // 평가 이력
                      _buildSectionTitle('평가 이력', Icons.assessment),
                      const SizedBox(height: 12),
                      _buildAssessmentHistorySection(),
                      const SizedBox(height: 24),

                      // 세션 이력
                      _buildSectionTitle('최근 세션 이력', Icons.event),
                      const SizedBox(height: 12),
                      _buildSessionHistorySection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '알 수 없는 오류',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadProgressData,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    final age = DateTime.now().year - widget.patient.birthDate.year;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.patient.name[0],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.patient.gender == 'M' ? '남' : '여'} / $age세',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '환자번호: ${widget.patient.patientCode}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGoalProgressChart() {
    if (_goalProgress.isEmpty) {
      return _buildEmptyState('설정된 목표가 없습니다');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _goalProgress.map((goal) {
                final progress = (goal['progress'] as num).toDouble();
                final status = goal['status'] as String;
                
                return PieChartSectionData(
                  value: progress,
                  title: '${progress.toStringAsFixed(0)}%',
                  color: status == 'ACHIEVED' ? Colors.green : Colors.blue,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentChart() {
    if (_assessmentHistory.isEmpty) {
      return _buildEmptyState('평가 이력이 없습니다');
    }

    // 날짜순 정렬 (오래된 것부터)
    final sortedData = List<Map<String, dynamic>>.from(_assessmentHistory)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final spots = sortedData.asMap().entries.map((entry) {
      final score = (entry.value['score'] as num).toDouble();
      return FlSpot(entry.key.toDouble(), score);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < sortedData.length) {
                        final date = sortedData[value.toInt()]['date'] as DateTime;
                        return Text(
                          '${date.month}/${date.day}',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionFrequencyChart() {
    if (_sessionHistory.isEmpty) {
      return _buildEmptyState('세션 이력이 없습니다');
    }

    // 월별 세션 개수 집계
    final monthlyCount = <String, int>{};
    for (var session in _sessionHistory) {
      final date = session['date'] as DateTime;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
    }

    final sortedKeys = monthlyCount.keys.toList()..sort();
    final barGroups = sortedKeys.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: monthlyCount[entry.value]!.toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < sortedKeys.length) {
                        final monthKey = sortedKeys[value.toInt()];
                        final parts = monthKey.split('-');
                        return Text(
                          '${parts[1]}월',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalProgressSection() {
    if (_goalProgress.isEmpty) {
      return _buildEmptyState('설정된 목표가 없습니다');
    }

    return Column(
      children: _goalProgress.map((goal) {
        final progress = (goal['progress'] as num).toDouble();
        final status = goal['status'] as String;
        final targetDate = goal['target_date'] as DateTime?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal['title'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 80 ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행률: ${progress.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    if (targetDate != null)
                      Text(
                        '목표일: ${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssessmentHistorySection() {
    if (_assessmentHistory.isEmpty) {
      return _buildEmptyState('평가 이력이 없습니다');
    }

    return Column(
      children: _assessmentHistory.map((assessment) {
        final date = assessment['date'] as DateTime;
        final type = assessment['type'] as String;
        final score = assessment['score'] as num;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.assignment, color: Colors.blue),
            ),
            title: Text(_getAssessmentTypeName(type)),
            subtitle: Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '점수: ${score.toString()}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSessionHistorySection() {
    if (_sessionHistory.isEmpty) {
      return _buildEmptyState('세션 이력이 없습니다');
    }

    return Column(
      children: _sessionHistory.take(10).map((session) {
        final date = session['date'] as DateTime;
        final type = session['type'] as String;
        final duration = session['duration'] as num;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.event, color: Colors.green),
            ),
            title: Text(_getSessionTypeName(type)),
            subtitle: Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} · ${duration}분',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'ACHIEVED':
        color = Colors.green;
        label = '달성';
        break;
      case 'IN_PROGRESS':
        color = Colors.blue;
        label = '진행중';
        break;
      default:
        color = Colors.grey;
        label = '대기';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _getAssessmentTypeName(String type) {
    switch (type) {
      case 'INITIAL':
        return '초기 평가';
      case 'INTERIM':
        return '중간 평가';
      case 'FINAL':
        return '최종 평가';
      default:
        return '일반 평가';
    }
  }

  String _getSessionTypeName(String type) {
    switch (type) {
      case 'PHYSICAL_THERAPY':
        return '물리치료';
      case 'OCCUPATIONAL_THERAPY':
        return '작업치료';
      case 'SPEECH_THERAPY':
        return '언어치료';
      default:
        return '치료 세션';
    }
  }
}

/// 보고서 생성 다이얼로그
class _ReportGeneratorDialog extends StatefulWidget {
  final Patient patient;
  final List<Map<String, dynamic>> assessmentHistory;
  final List<Map<String, dynamic>> sessionHistory;
  final List<Map<String, dynamic>> goalProgress;

  const _ReportGeneratorDialog({
    required this.patient,
    required this.assessmentHistory,
    required this.sessionHistory,
    required this.goalProgress,
  });

  @override
  State<_ReportGeneratorDialog> createState() => _ReportGeneratorDialogState();
}

class _ReportGeneratorDialogState extends State<_ReportGeneratorDialog> {
  final TextEditingController _reportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateReportContent();
  }

  void _generateReportContent() {
    final buffer = StringBuffer();
    
    // 헤더
    buffer.writeln('=== 재활 성과 보고서 ===\n');
    buffer.writeln('환자명: ${widget.patient.name}');
    buffer.writeln('환자번호: ${widget.patient.patientCode}');
    buffer.writeln('생년월일: ${widget.patient.birthDate.year}-${widget.patient.birthDate.month.toString().padLeft(2, '0')}-${widget.patient.birthDate.day.toString().padLeft(2, '0')}');
    buffer.writeln('보고서 작성일: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}\n');
    
    // 목표 달성 현황
    buffer.writeln('[ 목표 달성 현황 ]');
    if (widget.goalProgress.isEmpty) {
      buffer.writeln('- 설정된 목표가 없습니다.\n');
    } else {
      for (var goal in widget.goalProgress) {
        final progress = goal['progress'] as num;
        final status = goal['status'] as String;
        buffer.writeln('- ${goal['title']}');
        buffer.writeln('  진행률: ${progress}% (${status == 'ACHIEVED' ? '달성' : '진행중'})');
      }
      buffer.writeln();
    }
    
    // 평가 이력
    buffer.writeln('[ 평가 이력 ]');
    if (widget.assessmentHistory.isEmpty) {
      buffer.writeln('- 평가 이력이 없습니다.\n');
    } else {
      for (var assessment in widget.assessmentHistory.take(5)) {
        final date = assessment['date'] as DateTime;
        final score = assessment['score'] as num;
        buffer.writeln('- ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}: 점수 $score점');
      }
      buffer.writeln();
    }
    
    // 세션 참여 현황
    buffer.writeln('[ 세션 참여 현황 ]');
    buffer.writeln('총 세션 수: ${widget.sessionHistory.length}회');
    if (widget.sessionHistory.isNotEmpty) {
      final totalMinutes = widget.sessionHistory.fold<num>(0, (sum, session) => sum + (session['duration'] as num));
      buffer.writeln('총 참여 시간: ${totalMinutes}분 (${(totalMinutes / 60).toStringAsFixed(1)}시간)');
    }
    buffer.writeln();
    
    // 종합 의견
    buffer.writeln('[ 종합 의견 ]');
    buffer.writeln('환자는 꾸준한 치료 참여를 통해 긍정적인 변화를 보이고 있습니다.');
    if (widget.goalProgress.isNotEmpty) {
      final avgProgress = widget.goalProgress.fold<num>(0, (sum, goal) => sum + (goal['progress'] as num)) / widget.goalProgress.length;
      buffer.writeln('목표 달성률은 평균 ${avgProgress.toStringAsFixed(1)}%로 양호한 수준입니다.');
    }
    buffer.writeln('지속적인 치료와 관리가 필요하며, 보호자와의 긴밀한 협력이 중요합니다.');
    
    _reportController.text = buffer.toString();
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('재활 성과 보고서'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: TextField(
          controller: _reportController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '보고서 내용을 편집하세요...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: 보고서 저장 또는 출력 기능
            Navigator.pop(context, _reportController.text);
          },
          icon: const Icon(Icons.save),
          label: const Text('저장'),
        ),
      ],
    );
  }
}
