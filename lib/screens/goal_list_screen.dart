import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/goal.dart';
import '../constants/enums.dart';
import '../constants/goal_templates_helper.dart';
import 'goal_setting_screen.dart';

/// 목표 목록 및 관리 화면
class GoalListScreen extends StatefulWidget {
  final Patient patient;

  const GoalListScreen({
    super.key,
    required this.patient,
  });

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  List<Goal> _goals = [];
  bool _isLoading = false;
  GoalStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Firebase에서 목표 로드
    // final snapshot = await FirebaseFirestore.instance
    //     .collection('goals')
    //     .where('patient_id', isEqualTo: widget.patient.id)
    //     .orderBy('created_at', descending: true)
    //     .get();
    // _goals = snapshot.docs.map((doc) => Goal.fromFirestore(doc.data(), doc.id)).toList();

    // Mock 데이터 (테스트용)
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _goals = _createMockGoals();
      _isLoading = false;
    });
  }

  List<Goal> _createMockGoals() {
    return [
      Goal(
        id: 'goal_001',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        goalText: '8주 내 보조 없이 독립적으로 10m 보행하기',
        smartCriteria: SmartCriteria(
          specific: '보조 없이 독립적으로 10m 보행',
          measurable: '연속 10m 거리를 보조 도구 없이 걷기',
          achievable: '현재 보조 보행이 가능하며, 균형 능력 향상 중',
          relevant: '일상생활에서 독립성 증진에 필수적',
          timeBound: DateTime.now().add(const Duration(days: 56)),
        ),
        category: GoalCategory.functional,
        priority: GoalPriority.high,
        targetDate: DateTime.now().add(const Duration(days: 56)),
        status: GoalStatus.inProgress,
        progressPercentage: 35.0,
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
      ),
      Goal(
        id: 'goal_002',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        goalText: '6주 내 한 발로 10초간 균형 잡기',
        smartCriteria: SmartCriteria(
          specific: '한 발로 10초간 균형 유지',
          measurable: '한 발 서기 자세로 10초 이상 유지',
          achievable: '현재 양발 서기는 안정적이며, 균형 훈련 진행 중',
          relevant: '낙상 예방 및 일상 활동 안전성 증진',
          timeBound: DateTime.now().add(const Duration(days: 21)),
        ),
        category: GoalCategory.functional,
        priority: GoalPriority.high,
        targetDate: DateTime.now().add(const Duration(days: 21)),
        status: GoalStatus.inProgress,
        progressPercentage: 60.0,
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
      ),
      Goal(
        id: 'goal_003',
        patientId: widget.patient.id,
        therapistId: 'therapist_001',
        goalText: '12주 내 상지 근력 등급 Good 달성하기',
        smartCriteria: SmartCriteria(
          specific: '상지 근력 등급 Fair에서 Good으로 향상',
          measurable: 'MMT(도수근력검사) 등급 Good 달성',
          achievable: '현재 Fair 등급이며, 꾸준한 근력 운동 진행 중',
          relevant: '일상생활 동작(들기, 밀기) 수행 능력 향상',
          timeBound: DateTime.now().add(const Duration(days: 84)),
        ),
        category: GoalCategory.physical,
        priority: GoalPriority.medium,
        targetDate: DateTime.now().add(const Duration(days: 84)),
        status: GoalStatus.inProgress,
        progressPercentage: 25.0,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];
  }

  List<Goal> get _filteredGoals {
    if (_filterStatus == null) {
      return _goals;
    }
    return _goals.where((g) => g.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('목표 관리 - ${widget.patient.name}'),
        actions: [
          PopupMenuButton<GoalStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '필터',
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('전체'),
              ),
              PopupMenuItem(
                value: GoalStatus.inProgress,
                child: Text(GoalTemplatesHelper.getStatusDisplayName(GoalStatus.inProgress)),
              ),
              PopupMenuItem(
                value: GoalStatus.achieved,
                child: Text(GoalTemplatesHelper.getStatusDisplayName(GoalStatus.achieved)),
              ),
              PopupMenuItem(
                value: GoalStatus.revised,
                child: Text(GoalTemplatesHelper.getStatusDisplayName(GoalStatus.revised)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredGoals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGoals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(_filteredGoals[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToGoalSetting,
        icon: const Icon(Icons.add),
        label: const Text('새 목표'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _filterStatus == null ? '등록된 목표가 없습니다' : '해당하는 목표가 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToGoalSetting,
            icon: const Icon(Icons.add),
            label: const Text('새 목표 추가'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;
    final isNearDeadline = daysRemaining <= 7 && daysRemaining >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showGoalDetail(goal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 제목 + 상태
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      goal.goalText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(goal.status),
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
                    GoalTemplatesHelper.getCategoryDisplayName(goal.category),
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.priority_high,
                    GoalTemplatesHelper.getPriorityDisplayName(goal.priority),
                    goal.priority == GoalPriority.high ? Colors.red : Colors.orange,
                  ),
                  _buildInfoChip(
                    Icons.event,
                    isOverdue
                        ? '${daysRemaining.abs()}일 지남'
                        : '$daysRemaining일 남음',
                    isOverdue ? Colors.red : (isNearDeadline ? Colors.orange : Colors.green),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 진행률
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '진행률',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${goal.progressPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(goal.progressPercentage),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: goal.progressPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(goal.progressPercentage),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 날짜 정보
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '시작: ${DateFormat('yyyy-MM-dd').format(goal.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.flag, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '목표: ${DateFormat('yyyy-MM-dd').format(goal.targetDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GoalStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case GoalStatus.inProgress:
        color = Colors.blue;
        icon = Icons.play_circle;
        break;
      case GoalStatus.achieved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case GoalStatus.revised:
        color = Colors.orange;
        icon = Icons.edit;
        break;
      case GoalStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            GoalTemplatesHelper.getStatusDisplayName(status),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
  }

  void _showGoalDetail(Goal goal) {
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
          return _buildDetailSheet(goal, scrollController);
        },
      ),
    );
  }

  Widget _buildDetailSheet(Goal goal, ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // 제목
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.goalText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(goal.status),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 진행률
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '목표 진행률',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${goal.progressPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // SMART 기준
          const Text(
            'SMART 기준',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          _buildSmartItem('Specific (구체적)', goal.smartCriteria.specific, Icons.my_location),
          _buildSmartItem('Measurable (측정 가능)', goal.smartCriteria.measurable, Icons.straighten),
          _buildSmartItem('Achievable (달성 가능)', goal.smartCriteria.achievable, Icons.trending_up),
          _buildSmartItem('Relevant (관련성)', goal.smartCriteria.relevant, Icons.link),
          _buildSmartItem(
            'Time-bound (기한)',
            DateFormat('yyyy년 MM월 dd일').format(goal.smartCriteria.timeBound),
            Icons.event,
          ),
          
          const SizedBox(height: 24),
          
          // 기본 정보
          const Text(
            '기본 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('카테고리', GoalTemplatesHelper.getCategoryDisplayName(goal.category)),
          _buildInfoRow('우선순위', GoalTemplatesHelper.getPriorityDisplayName(goal.priority)),
          _buildInfoRow('생성일', DateFormat('yyyy-MM-dd').format(goal.createdAt)),
          _buildInfoRow('목표일', DateFormat('yyyy-MM-dd').format(goal.targetDate)),
          
          const SizedBox(height: 32),
          
          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateProgress(goal);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('진행률 업데이트'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('닫기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartItem(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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

  void _updateProgress(Goal goal) {
    showDialog(
      context: context,
      builder: (context) {
        double newProgress = goal.progressPercentage;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('진행률 업데이트'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('현재: ${goal.progressPercentage.toStringAsFixed(0)}%'),
                  const SizedBox(height: 16),
                  Slider(
                    value: newProgress,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${newProgress.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() {
                        newProgress = value;
                      });
                    },
                  ),
                  Text(
                    '새 진행률: ${newProgress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Firebase 업데이트
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('진행률이 업데이트되었습니다')),
                    );
                    _loadGoals();
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToGoalSetting() async {
    final result = await Navigator.push<Goal>(
      context,
      MaterialPageRoute(
        builder: (context) => GoalSettingScreen(patient: widget.patient),
      ),
    );

    if (result != null) {
      _loadGoals();
    }
  }
}
