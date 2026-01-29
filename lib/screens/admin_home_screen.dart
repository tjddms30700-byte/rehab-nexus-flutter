import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';

/// 센터장 홈 화면 - 운영 + 한눈에 파악
/// 공통 원칙: Action-first, 메뉴 탐색 금지, '지금 해야 할 것'부터 보여주기
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // KPI 데이터
  int _todayScheduleCount = 0;
  int _attendedCount = 0;
  int _pendingAttendanceCount = 0;
  int _unpaidCount = 0;
  int _activeFixedScheduleCount = 0;
  
  // 오늘 할 일 데이터
  int _pendingMakeupCount = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // 1. 오늘 수업 수
      final todaySchedules = await _firestore
          .collection('appointments')
          .where('appointment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointment_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      _todayScheduleCount = todaySchedules.docs.length;

      // 2. 출석 완료 / 미처리
      _attendedCount = todaySchedules.docs.where((doc) => doc.data()['attended'] == true).length;
      _pendingAttendanceCount = todaySchedules.docs.where((doc) {
        final data = doc.data();
        return data['attended'] != true && data['status'] != 'cancelled';
      }).length;

      // 3. 미수납 건수 (status가 'pending'인 payments)
      final unpaidPayments = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'pending')
          .get();
      
      _unpaidCount = unpaidPayments.docs.length;

      // 4. 진행 중 고정수업 수 (fixed_schedules에서 active인 것들)
      final activeFixed = await _firestore
          .collection('fixed_schedules')
          .where('status', isEqualTo: 'active')
          .get();
      
      _activeFixedScheduleCount = activeFixed.docs.length;

      // 5. 보강 승인 대기 (makeup_tickets에서 status가 'pending'인 것들)
      final pendingMakeups = await _firestore
          .collection('makeup_tickets')
          .where('status', isEqualTo: 'pending')
          .get();
      
      _pendingMakeupCount = pendingMakeups.docs.length;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    final userName = user?.name ?? '센터장';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/app_icon.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('AQU LAB Care', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 헤더
                    _buildHeader(userName),
                    const SizedBox(height: 24),
                    
                    // 핵심 KPI 카드 (2×2)
                    _buildKPISection(),
                    const SizedBox(height: 24),
                    
                    // 오늘 할 일 카드
                    _buildTodayTasksSection(),
                    const SizedBox(height: 24),
                    
                    // 빠른 이동
                    _buildQuickActionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요, ${userName}님 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘 센터 운영 현황입니다',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '핵심 지표',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: '오늘 수업 수',
                value: '$_todayScheduleCount',
                icon: Icons.calendar_today,
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                title: '출석 완료',
                value: '$_attendedCount',
                icon: Icons.check_circle,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: '출석 미처리',
                value: '$_pendingAttendanceCount',
                icon: Icons.pending_actions,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                title: '미수납 건수',
                value: '$_unpaidCount',
                icon: Icons.payment,
                color: const Color(0xFFE91E63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildKPICard(
          title: '진행 중 고정수업',
          value: '$_activeFixedScheduleCount',
          icon: Icons.repeat,
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksSection() {
    // 오늘 할 일 카드들
    final tasks = <Widget>[];

    if (_pendingAttendanceCount > 0) {
      tasks.add(_buildTaskCard(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFF9800),
        title: '출석 미처리',
        subtitle: '$_pendingAttendanceCount건',
        onTap: () {
          // 일정 관리로 이동
          Navigator.of(context).pushNamed('/calendar_schedule');
        },
      ));
    }

    if (_unpaidCount > 0) {
      tasks.add(_buildTaskCard(
        icon: Icons.attach_money,
        iconColor: const Color(0xFFE91E63),
        title: '미수납',
        subtitle: '$_unpaidCount건',
        onTap: () {
          // 수납 관리로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('수납 관리 화면으로 이동합니다')),
          );
        },
      ));
    }

    if (_pendingMakeupCount > 0) {
      tasks.add(_buildTaskCard(
        icon: Icons.autorenew,
        iconColor: const Color(0xFF2196F3),
        title: '보강 승인 대기',
        subtitle: '$_pendingMakeupCount건',
        onTap: () {
          // 보강 관리로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('보강 관리 화면으로 이동합니다')),
          );
        },
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 할 일',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          _buildEmptyTaskCard()
        else
          ...tasks,
      ],
    );
  }

  Widget _buildTaskCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTaskCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 28),
          SizedBox(width: 12),
          Text(
            '오늘 할 일 없음 👍',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 이동',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.calendar_today,
                title: '오늘 일정 보기',
                color: const Color(0xFF1976D2),
                onTap: () {
                  Navigator.of(context).pushNamed('/calendar_schedule');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.payment,
                title: '수납 관리',
                color: const Color(0xFFE91E63),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('수납 관리 화면으로 이동합니다')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          icon: Icons.people,
          title: '이용자 관리',
          color: const Color(0xFF4CAF50),
          onTap: () {
            Navigator.of(context).pushNamed('/patient_management');
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
