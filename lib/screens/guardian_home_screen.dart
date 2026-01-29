import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../models/patient.dart';
import '../constants/app_theme.dart';
import 'guardian_report_screen.dart';
import 'guardian_home_program_screen.dart';
import 'appointment_request_screen_debug.dart';
import 'inquiry_create_screen_debug.dart';

/// 보호자 홈 화면 - 안심 + 간결
/// 공통 원칙: Action-first, '확인·안심·연결'이 핵심
class GuardianHomeScreen extends StatefulWidget {
  final AppUser user;

  const GuardianHomeScreen({super.key, required this.user});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Patient> _myPatients = [];
  Map<String, dynamic>? _upcomingAppointment;
  int _unreadReportsCount = 0;
  int _unreadNoticesCount = 0;
  bool _isLoading = true;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _loadHomeData();
  }

  Future<void> _checkFirstTime() async {
    // 첫 진입 여부 확인 (SharedPreferences 대신 간단히 상태로 관리)
    // 실제로는 SharedPreferences로 저장
    setState(() {
      _showTutorial = false; // 튜토리얼 기능은 별도로 구현
    });
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = widget.user;

      // 1. 내 환자 목록 불러오기 (guardians 배열에 내 user.id가 포함된 환자)
      final patientsSnapshot = await _firestore
          .collection('patients')
          .where('guardians', arrayContains: user.id)
          .get();

      _myPatients = patientsSnapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .toList();

      // 2. 오늘/다가오는 일정 불러오기 (가장 가까운 예약 1개)
      if (_myPatients.isNotEmpty) {
        final patientIds = _myPatients.map((p) => p.id).toList();
        
        final now = DateTime.now();
        final appointmentsSnapshot = await _firestore
            .collection('appointments')
            .where('patient_id', whereIn: patientIds)
            .where('appointment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .orderBy('appointment_date')
            .limit(1)
            .get();

        if (appointmentsSnapshot.docs.isNotEmpty) {
          _upcomingAppointment = appointmentsSnapshot.docs.first.data();
          _upcomingAppointment!['id'] = appointmentsSnapshot.docs.first.id;
        }
      }

      // 3. 읽지 않은 리포트 수 (예시)
      _unreadReportsCount = 0; // 실제로는 sessions에서 guardian_viewed == false인 것들

      // 4. 읽지 않은 공지사항 수 (예시)
      _unreadNoticesCount = 0;

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
    final user = widget.user;
    final userName = user.name;

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
            onPressed: _loadHomeData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              appState.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 인사
                    _buildHeader(userName),
                    const SizedBox(height: 24),
                    
                    // 오늘/다가오는 일정
                    if (_upcomingAppointment != null) ...[
                      _buildUpcomingAppointmentCard(),
                      const SizedBox(height: 24),
                    ],
                    
                    // 핵심 카드 3개
                    _buildCoreCardsSection(),
                    const SizedBox(height: 24),
                    
                    // 알림 및 업데이트
                    _buildAlertsSection(),
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
            '아이의 치료 정보를 확인하세요',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard() {
    if (_upcomingAppointment == null) return const SizedBox.shrink();

    final appointmentDate = (_upcomingAppointment!['appointment_date'] as Timestamp).toDate();
    final timeSlot = _upcomingAppointment!['time_slot'] ?? '';
    final patientName = _upcomingAppointment!['patient_name'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                '다가오는 일정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${appointmentDate.month}월 ${appointmentDate.day}일 $timeSlot',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                patientName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                '위례아쿠수중운동센터',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 메뉴',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        _buildCoreCard(
          icon: Icons.description,
          iconColor: const Color(0xFF2196F3),
          title: '최근 치료 리포트',
          subtitle: '세션 기록 및 성과 확인',
          badgeCount: _unreadReportsCount,
          onTap: () {
            if (_myPatients.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuardianReportScreen(
                    user: widget.user,
                    patientId: _myPatients.first.id,
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildCoreCard(
          icon: Icons.fitness_center,
          iconColor: const Color(0xFF4CAF50),
          title: '홈프로그램',
          subtitle: '가정에서 할 수 있는 운동',
          onTap: () {
            if (_myPatients.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuardianHomeProgramScreen(patient: _myPatients.first),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildCoreCard(
          icon: Icons.chat_bubble,
          iconColor: const Color(0xFFFF9800),
          title: '문의하기',
          subtitle: '치료사에게 연락',
          onTap: () {
            if (_myPatients.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InquiryCreateScreen(patient: _myPatients.first),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildCoreCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    int badgeCount = 0,
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
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
    );
  }

  Widget _buildAlertsSection() {
    // 예시 알림 (실제로는 Firestore에서 가져오기)
    final alerts = <Widget>[];

    if (_unreadNoticesCount > 0) {
      alerts.add(_buildAlertCard(
        icon: Icons.notifications,
        iconColor: const Color(0xFFFF9800),
        message: '새 공지사항 $_unreadNoticesCount건',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공지사항 화면으로 이동합니다')),
          );
        },
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '알림',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
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
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                SizedBox(width: 12),
                Text(
                  '새 알림이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          )
        else
          ...alerts,
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconColor,
    required String message,
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
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
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
}
