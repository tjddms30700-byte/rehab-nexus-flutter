import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/home_program.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

/// 보호자용 홈프로그램 화면 (가정 운동 과제)
class GuardianHomeProgramScreen extends StatefulWidget {
  final Patient patient;

  const GuardianHomeProgramScreen({
    super.key,
    required this.patient,
  });

  @override
  State<GuardianHomeProgramScreen> createState() => _GuardianHomeProgramScreenState();
}

class _GuardianHomeProgramScreenState extends State<GuardianHomeProgramScreen> {
  HomeProgram? _currentProgram;
  final Map<String, bool> _activityCompletion = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeProgram();
  }

  Future<void> _loadHomeProgram() async {
    setState(() => _isLoading = true);
    
    try {
      // Mock 데이터로 홈프로그램 생성
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final mockProgram = HomeProgram(
        id: 'hp_001',
        patientId: widget.patient.id,
        month: month,
        goals: [
          '균형 감각 향상',
          '수중 호흡 조절 능력 강화',
          '상지 근력 증진',
        ],
        activities: [
          HomeActivity(
            activityId: 'activity_001',
            title: '물속 균형 잡기 연습',
            description: '욕조나 풀에서 안전하게 균형을 잡는 연습입니다.',
            frequency: '주 3회',
            duration: '15분',
            instructions: [
              '1. 부모님이 잡아주는 상태에서 한 발로 서기',
              '2. 10초간 자세 유지하기',
              '3. 좌우 번갈아가며 3회 반복',
            ],
            precautions: [
              '항상 보호자가 함께 진행합니다',
              '미끄럼 방지 매트를 사용합니다',
            ],
          ),
          HomeActivity(
            activityId: 'activity_002',
            title: '호흡 조절 게임',
            description: '물에 대한 두려움을 줄이고 호흡을 조절하는 연습입니다.',
            frequency: '매일',
            duration: '10분',
            instructions: [
              '1. 세숫대야에 물을 담습니다',
              '2. 코로 숨을 들이마시고 입으로 천천히 내쉽니다',
              '3. 물에 입을 담그고 거품을 만들어봅니다',
            ],
            precautions: [
              '물 깊이는 얕게 유지합니다',
              '강요하지 않고 놀이처럼 진행합니다',
            ],
          ),
          HomeActivity(
            activityId: 'activity_003',
            title: '팔 운동 (수건 활용)',
            description: '수건을 이용하여 팔 근력을 강화하는 운동입니다.',
            frequency: '주 4회',
            duration: '20분',
            instructions: [
              '1. 수건을 양손으로 잡습니다',
              '2. 팔을 앞으로 쭉 뻗었다 당깁니다',
              '3. 10회 반복합니다',
            ],
            precautions: [
              '어깨에 통증이 없는지 확인합니다',
              '천천히 움직입니다',
            ],
          ),
        ],
        status: HomeProgramStatus.active,
        createdAt: DateTime.now(),
      );

      setState(() {
        _currentProgram = mockProgram;
        _isLoading = false;
        
        // 완료 상태 초기화
        for (var activity in mockProgram.activities) {
          _activityCompletion[activity.activityId] = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('홈프로그램을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  void _toggleActivityCompletion(String activityId) {
    setState(() {
      _activityCompletion[activityId] = !(_activityCompletion[activityId] ?? false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _activityCompletion[activityId]! 
            ? '운동을 완료했습니다! 잘하셨어요 👏' 
            : '체크를 해제했습니다',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈프로그램'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHomeProgram,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentProgram == null
              ? _buildEmptyState()
              : _buildProgramContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '아직 홈프로그램이 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramContent() {
    final program = _currentProgram!;
    final completedCount = _activityCompletion.values.where((v) => v).length;
    final totalCount = program.activities.length;
    final progressPercentage = totalCount > 0 ? (completedCount / totalCount * 100).toInt() : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 환자 정보
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(widget.patient.name.substring(0, 1)),
            ),
            title: Text(widget.patient.name),
            subtitle: Text('${widget.patient.age}세'),
          ),
        ),
        const SizedBox(height: 16),

        // 진행률
        Card(
          color: const Color(0x1A0077BE), // AppTheme.primary with 10% opacity
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('이번 주 진행률', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$progressPercentage%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: completedCount / totalCount),
                const SizedBox(height: 4),
                Text('$completedCount / $totalCount 활동 완료'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 목표
        const Text('이달의 목표', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: program.goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 20, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(goal)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 활동 목록
        const Text('가정 운동 과제', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        ...program.activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isCompleted = _activityCompletion[activity.activityId] ?? false;
          
          return _buildActivityCard(activity, index + 1, isCompleted);
        }),
      ],
    );
  }

  Widget _buildActivityCard(HomeActivity activity, int number, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => _toggleActivityCompletion(activity.activityId),
        ),
        title: Text(
          '$number. ${activity.title}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.schedule, size: 14),
            const SizedBox(width: 4),
            Text(activity.frequency),
            const SizedBox(width: 12),
            const Icon(Icons.timer, size: 14),
            const SizedBox(width: 4),
            Text(activity.duration),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description),
                const SizedBox(height: 16),
                const Text('📋 수행 방법', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...activity.instructions.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(i, style: const TextStyle(fontSize: 14)),
                )),
                const SizedBox(height: 16),
                const Text('⚠️ 주의사항', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...activity.precautions.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $p', style: const TextStyle(fontSize: 14)),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
