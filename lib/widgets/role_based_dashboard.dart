import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/appointment.dart';
import '../constants/user_roles.dart';
import '../constants/enums.dart';

/// 역할별 Action-first 대시보드
/// 
/// 치료사: 오늘 일정 + 임상 작업
/// 센터장/관리자: 운영 현황 + 오늘 할 일
class RoleBasedDashboard extends StatefulWidget {
  final AppUser user;
  final Function(String)? onNavigate; // 메뉴 이동 콜백

  const RoleBasedDashboard({
    super.key, 
    required this.user,
    this.onNavigate,
  });

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard> {
  List<Appointment> _todayAppointments = [];
  bool _isLoading = true;

  // 통계 데이터
  int _todayTotalAppointments = 0;
  int _todayAttendedCount = 0;
  int _todayPendingCount = 0;
  int _unpaidCount = 0;
  int _activeFixedSchedules = 0;
  int _unfinishedSessions = 0;
  int _goalsToReview = 0;
  int _makeupRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 오늘 일정 조회
      Query appointmentsQuery = FirebaseFirestore.instance
          .collection('appointments')
          .where('appointment_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointment_date',
              isLessThan: Timestamp.fromDate(endOfDay));

      // ✅ 치료사 전용 역할이면 자신의 일정만 (owner/admin은 모든 일정 표시)
      final isTherapistOnly = widget.user.hasRole(UserRole.therapist) && 
                              !widget.user.hasAnyRole([UserRole.superAdmin, UserRole.centerAdmin]) &&
                              widget.user.roles['owner'] != true &&
                              widget.user.roles['admin'] != true;
      
      if (isTherapistOnly) {
        appointmentsQuery =
            appointmentsQuery.where('therapist_id', isEqualTo: widget.user.id);
      }

      final appointmentsSnapshot = await appointmentsQuery.get();

      _todayAppointments = appointmentsSnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      _todayAppointments
          .sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      // 통계 계산
      _todayTotalAppointments = _todayAppointments.length;
      _todayAttendedCount =
          _todayAppointments.where((a) => a.attended).length;
      _todayPendingCount = _todayAppointments
          .where((a) =>
              a.status == AppointmentStatus.pending ||
              (!a.attended && a.appointmentDate.isBefore(DateTime.now())))
          .length;

      // 실제 미수납 건수 조회
      await _loadUnpaidCount();
      
      // 고정수업 수 조회
      await _loadActiveFixedSchedules();
      
      // 세션 기록 미완 조회 (치료사 역할 있으면)
      if (widget.user.hasRole(UserRole.therapist) || widget.user.roles['therapist'] == true) {
        await _loadUnfinishedSessions();
      }
      
      // 보강 요청 조회 (센터장/관리자 역할 있으면)
      if (widget.user.hasAnyRole([UserRole.centerAdmin, UserRole.superAdmin]) ||
          widget.user.roles['owner'] == true ||
          widget.user.roles['admin'] == true) {
        await _loadMakeupRequests();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadUnpaidCount() async {
    try {
      // payments 컬렉션에서 미수납 건수 조회
      final unpaidSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('payment_status', isEqualTo: 'pending')
          .get();
      
      _unpaidCount = unpaidSnapshot.docs.length;
    } catch (e) {
      _unpaidCount = 0;
    }
  }
  
  Future<void> _loadActiveFixedSchedules() async {
    try {
      // fixed_schedules 컬렉션에서 활성 고정수업 조회
      final fixedSchedulesSnapshot = await FirebaseFirestore.instance
          .collection('fixed_schedules')
          .where('status', isEqualTo: 'active')
          .get();
      
      _activeFixedSchedules = fixedSchedulesSnapshot.docs.length;
    } catch (e) {
      _activeFixedSchedules = 0;
    }
  }
  
  Future<void> _loadUnfinishedSessions() async {
    try {
      // 오늘 출석 완료했지만 세션 기록이 없는 예약
      _unfinishedSessions = _todayAppointments
          .where((a) => a.attended && !a.sessionRecorded)
          .length;
      
      // TODO: 목표 점검 대상은 별도 로직 필요
      _goalsToReview = 0;
    } catch (e) {
      _unfinishedSessions = 0;
      _goalsToReview = 0;
    }
  }
  
  Future<void> _loadMakeupRequests() async {
    try {
      // makeup_tickets 컬렉션에서 승인 대기 중인 보강권 조회
      final makeupSnapshot = await FirebaseFirestore.instance
          .collection('makeup_tickets')
          .where('status', isEqualTo: 'pending')
          .get();
      
      _makeupRequests = makeupSnapshot.docs.length;
    } catch (e) {
      _makeupRequests = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 역할에 따라 다른 홈 화면
    if (widget.user.role == UserRole.therapist) {
      return _buildTherapistHome();
    } else {
      return _buildAdminHome();
    }
  }

  /// 🧑‍⚕️ 치료사 Home (임상 집중형)
  Widget _buildTherapistHome() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 인사
            _buildTherapistGreeting(),
            const SizedBox(height: 24),

            // 오늘 일정 카드
            _buildTodayScheduleCards(),
            const SizedBox(height: 16),

            // 오늘 해야 할 임상
            _buildClinicalTasks(),
            const SizedBox(height: 24),

            // 빠른 버튼
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTherapistGreeting() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.user.name} 치료사님',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 일정 ${_todayTotalAppointments}건이 있습니다',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleCards() {
    if (_todayAppointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.calendar_today,
                size: 48,
                color: Color(0xFFCCCCCC),
              ),
              SizedBox(height: 12),
              Text(
                '오늘 예정된 일정이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 일정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _todayAppointments.length > 5 ? 5 : _todayAppointments.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAppointmentCard(_todayAppointments[index]),
          ),
        ),
        if (_todayAppointments.length > 5)
          TextButton(
            onPressed: () {
              // TODO: 전체 일정 보기
            },
            child: Text('전체 ${_todayAppointments.length}건 보기'),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final timeStr = _formatTime(appointment.appointmentDate);
    String statusText;
    Color statusColor;

    if (appointment.attended) {
      statusText = '출석 완료';
      statusColor = const Color(0xFF4CAF50);
    } else if (appointment.appointmentDate.isBefore(DateTime.now())) {
      statusText = '출석 처리';
      statusColor = const Color(0xFFFF9800);
    } else {
      statusText = '예정';
      statusColor = const Color(0xFF2196F3);
    }

    return InkWell(
      onTap: () {
        // 일정관리 화면으로 이동
        if (widget.onNavigate != null) {
          widget.onNavigate!('schedule');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 시간
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 환자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            // 화살표
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalTasks() {
    if (_unfinishedSessions == 0 && _goalsToReview == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 해야 할 임상',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        if (_unfinishedSessions > 0)
          _buildTaskCard(
            icon: Icons.description,
            iconColor: const Color(0xFFFF9800),
            title: '세션 기록 미완',
            subtitle: '$_unfinishedSessions건',
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!('session');
              }
            },
          ),
        if (_unfinishedSessions > 0 && _goalsToReview > 0)
          const SizedBox(height: 12),
        if (_goalsToReview > 0)
          _buildTaskCard(
            icon: Icons.flag,
            iconColor: const Color(0xFF4CAF50),
            title: '목표 점검 대상',
            subtitle: '$_goalsToReview명',
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!('goals');
              }
            },
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 접근',
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
              child: _buildQuickActionButton(
                icon: Icons.calendar_today,
                label: '오늘 일정',
                color: const Color(0xFF2196F3),
                onTap: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!('schedule');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.search,
                label: '환자 검색',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!('patients');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.edit,
                label: '세션 기록',
                color: const Color(0xFFFF9800),
                onTap: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!('session');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 👑 센터장 Home (운영 + 한눈에 파악)
  Widget _buildAdminHome() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더
            _buildAdminGreeting(),
            const SizedBox(height: 24),

            // 핵심 KPI 카드
            _buildKPICards(),
            const SizedBox(height: 16),

            // 오늘 할 일 카드
            _buildAdminTasks(),
            const SizedBox(height: 16),

            // 빠른 이동
            _buildAdminQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminGreeting() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '안녕하세요, 센터장님',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 센터 운영 현황입니다',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isDesktop ? 3.0 : 1.5, // 웹: 가로로 넓게, 모바일: 정사각형
          children: [
            _buildKPICard(
              icon: Icons.calendar_today,
              title: '오늘 수업 수',
              value: '$_todayTotalAppointments건',
              color: const Color(0xFF2196F3),
            ),
            _buildKPICard(
              icon: Icons.check_circle,
              title: '출석 완료',
              value: '$_todayAttendedCount / $_todayTotalAppointments',
              color: const Color(0xFF4CAF50),
            ),
            _buildKPICard(
              icon: Icons.payments,
              title: '미수납 건수',
              value: '$_unpaidCount건',
              color: const Color(0xFFFF9800),
            ),
            _buildKPICard(
              icon: Icons.repeat,
              title: '진행 중 고정수업',
              value: '$_activeFixedSchedules개',
              color: const Color(0xFF9C27B0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTasks() {
    final pendingAttendance = _todayPendingCount;
    final unpaid = _unpaidCount;
    final makeupRequests = _makeupRequests;

    if (pendingAttendance == 0 && unpaid == 0 && makeupRequests == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              '오늘 할 일 없음 👍',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
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
        if (pendingAttendance > 0)
          _buildTaskCard(
            icon: Icons.warning,
            iconColor: const Color(0xFFFF9800),
            title: '출석 미처리',
            subtitle: '$pendingAttendance건',
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!('schedule');
              }
            },
          ),
        if (pendingAttendance > 0 && unpaid > 0) const SizedBox(height: 12),
        if (unpaid > 0)
          _buildTaskCard(
            icon: Icons.payments,
            iconColor: const Color(0xFFF44336),
            title: '미수납',
            subtitle: '$unpaid건',
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!('payment');
              }
            },
          ),
        if (unpaid > 0 && makeupRequests > 0) const SizedBox(height: 12),
        if (makeupRequests > 0)
          _buildTaskCard(
            icon: Icons.repeat,
            iconColor: const Color(0xFF2196F3),
            title: '보강 요청',
            subtitle: '$makeupRequests건',
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!('makeup');
              }
            },
          ),
      ],
    );
  }

  Widget _buildAdminQuickActions() {
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
        _buildQuickActionLarge(
          icon: Icons.calendar_today,
          title: '오늘 일정 보기',
          color: const Color(0xFF2196F3),
          onTap: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('schedule');
            }
          },
        ),
        const SizedBox(height: 12),
        _buildQuickActionLarge(
          icon: Icons.payments,
          title: '수납 관리',
          color: const Color(0xFF4CAF50),
          onTap: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('payment');
            }
          },
        ),
        const SizedBox(height: 12),
        _buildQuickActionLarge(
          icon: Icons.people,
          title: '이용자 관리',
          color: const Color(0xFFFF9800),
          onTap: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('patients');
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionLarge({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
