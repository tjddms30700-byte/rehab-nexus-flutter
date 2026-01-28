import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../constants/enums.dart';

/// 성과 추이 화면
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

                      // 목표 진행도
                      _buildSectionTitle('목표 진행도', Icons.track_changes),
                      const SizedBox(height: 12),
                      _buildGoalProgressSection(),
                      const SizedBox(height: 24),

                      // 평가 이력
                      _buildSectionTitle('평가 이력', Icons.assessment),
                      const SizedBox(height: 12),
                      _buildAssessmentHistorySection(),
                      const SizedBox(height: 24),

                      // 세션 이력
                      _buildSectionTitle('세션 이력', Icons.calendar_month),
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
            onTap: () {
              // TODO: 세션 상세보기
            },
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
