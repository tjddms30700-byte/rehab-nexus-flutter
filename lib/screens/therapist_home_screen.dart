import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/responsive_layout.dart';
import 'patient_registration_screen.dart';
import 'calendar_schedule_screen.dart';
import 'patient_management_screen.dart';
import 'notice_list_screen.dart';
import 'file_library_screen.dart';
import 'makeup_ticket_list_screen.dart';
import 'voucher_list_screen.dart';
import 'payment_list_screen.dart';
// 임상 기능 화면 추가
import 'clinical_feature_patient_selector.dart';
import 'admin_settings_screen.dart';
import 'invite_management_screen.dart';

/// 치료사 홈 화면 - 반응형 웹/모바일
class TherapistHomeScreen extends StatelessWidget {
  const TherapistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _TherapistHomeMobile(),
      desktop: _TherapistHomeDesktop(),
    );
  }
}

/// 모바일 버전 (기존)
class _TherapistHomeMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AQU LAB Care - 치료사'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              appState.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _buildContent(context, user),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(context, user),
        const SizedBox(height: 24),
        _buildOperationsSection(context),
        const SizedBox(height: 24),
        _buildClinicalSection(context),
      ],
    );
  }
}

/// 데스크톱 웹 버전 - 사이드바 + 대시보드
class _TherapistHomeDesktop extends StatefulWidget {
  @override
  State<_TherapistHomeDesktop> createState() => _TherapistHomeDesktopState();
}

class _TherapistHomeDesktopState extends State<_TherapistHomeDesktop> {
  String _selectedMenu = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;

    return Scaffold(
      body: Row(
        children: [
          // 좌측 사이드바
          _buildSidebar(context, user, appState),
          
          // 우측 메인 컨텐츠
          Expanded(
            child: _buildMainContent(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, dynamic user, AppState appState) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name[0],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '치료사',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // 메뉴 - 3대 영역 구조
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // ========================================
                // ① 오늘 할 일 (Daily Ops) - 가장 위
                // ========================================
                _buildSectionHeader('📅 오늘 할 일', Colors.orange),
                _buildSidebarMenuItem(
                  icon: Icons.home,
                  title: '대시보드',
                  value: 'dashboard',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.today,
                  title: '오늘 일정',
                  value: 'today_schedule',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.check_circle_outline,
                  title: '출석/수업 처리',
                  value: 'attendance',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.edit_note,
                  title: '오늘 세션 기록',
                  value: 'today_session',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.notifications,
                  title: '오늘 알림',
                  value: 'today_notice',
                ),
                
                const Divider(height: 24),
                
                // ========================================
                // ② 센터 운영 (Center Ops)
                // ========================================
                _buildSectionHeader('🏢 센터 운영', Colors.blue),
                _buildSidebarMenuItem(
                  icon: Icons.calendar_today,
                  title: '일정 관리',
                  value: 'schedule',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.people,
                  title: '이용자 관리',
                  value: 'patients',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.confirmation_number,
                  title: '보강·이월 관리',
                  value: 'makeup',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.card_giftcard,
                  title: '바우처 관리',
                  value: 'voucher',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.payments,
                  title: '수납·정산',
                  value: 'payment',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.campaign,
                  title: '공지사항',
                  value: 'notice',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.folder,
                  title: '자료실',
                  value: 'files',
                ),
                
                const Divider(height: 24),
                
                // ========================================
                // ③ 임상 관리 (Clinical)
                // ========================================
                _buildSectionHeader('🩺 임상 관리', Colors.green),
                _buildSidebarMenuItem(
                  icon: Icons.person_add,
                  title: '환자 등록',
                  value: 'register',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.assessment,
                  title: '평가 입력',
                  value: 'assessment',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.flag,
                  title: '목표 관리 (SMART)',
                  value: 'goals',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.lightbulb_outline,
                  title: '콘텐츠 추천',
                  value: 'content',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.edit_note,
                  title: '세션 기록',
                  value: 'session',
                ),
                _buildSidebarMenuItem(
                  icon: Icons.trending_up,
                  title: '성과 추이',
                  value: 'progress',
                ),
                
                const Divider(height: 24),
                
                // ========================================
                // 관리자 메뉴 (센터장 전용)
                // ========================================
                if (user.role == 'ADMIN') ...[
                  _buildSidebarMenuItem(
                    icon: Icons.mail,
                    title: '초대 관리',
                    value: 'invites',
                  ),
                  _buildSidebarMenuItem(
                    icon: Icons.settings,
                    title: '환경설정',
                    value: 'settings',
                  ),
                ],
              ],
            ),
          ),

          // 로그아웃
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                appState.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 섹션 헤더 위젯
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isSelected = _selectedMenu == value;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedMenu = value;
        });
      },
    );
  }

  Widget _buildMainContent(BuildContext context, dynamic user) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // 상단 헤더
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMenuTitle(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMenuSubtitle(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 알림 버튼
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined, size: 28),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // 메인 컨텐츠
          Expanded(
            child: _buildSelectedContent(context, user),
          ),
        ],
      ),
    );
  }

  String _getMenuTitle() {
    switch (_selectedMenu) {
      case 'dashboard': return '대시보드';
      // 오늘 할 일
      case 'today_schedule': return '오늘 일정';
      case 'attendance': return '출석/수업 처리';
      case 'today_session': return '오늘 세션 기록';
      case 'today_notice': return '오늘 알림';
      // 센터 운영
      case 'schedule': return '일정 관리';
      case 'patients': return '이용자 관리';
      case 'makeup': return '보강·이월 관리';
      case 'voucher': return '바우처 관리';
      case 'payment': return '수납·정산';
      case 'notice': return '공지사항';
      case 'files': return '자료실';
      // 임상 관리
      case 'register': return '환자 등록';
      case 'assessment': return '평가 입력';
      case 'goals': return '목표 관리 (SMART)';
      case 'content': return '콘텐츠 추천';
      case 'session': return '세션 기록';
      case 'progress': return '성과 추이';
      // 관리자
      case 'invites': return '초대 관리';
      case 'settings': return '환경설정';
      default: return '대시보드';
    }
  }

  String _getMenuSubtitle() {
    switch (_selectedMenu) {
      case 'dashboard': return '오늘의 주요 정보를 한눈에 확인하세요';
      // 오늘 할 일
      case 'today_schedule': return '오늘 예정된 수업과 일정을 확인하세요';
      case 'attendance': return '오늘 출석과 수업 처리를 진행하세요';
      case 'today_session': return '오늘 진행한 세션을 기록하세요';
      case 'today_notice': return '오늘의 알림과 공지를 확인하세요';
      // 센터 운영
      case 'schedule': return '예약 및 출석 현황을 관리하세요';
      case 'patients': return '이용자 목록을 확인하고 관리하세요';
      case 'makeup': return '보강권과 이월 현황을 관리하세요';
      case 'voucher': return '바우처 프로그램을 관리하세요';
      case 'payment': return '수납 및 정산 내역을 확인하세요';
      // 임상 관리
      case 'register': return '새로운 환자를 등록하세요';
      case 'assessment': return '환자의 평가를 입력하고 관리하세요';
      case 'goals': return 'SMART 목표를 설정하고 관리하세요';
      case 'content': return '환자에게 맞는 콘텐츠를 추천하세요';
      case 'session': return '세션 기록을 작성하세요';
      case 'progress': return '환자의 성과 추이를 확인하세요';
      // 관리자
      case 'invites': return '팀원과 보호자를 초대하고 관리하세요';
      default: return '';
    }
  }

  Widget _buildSelectedContent(BuildContext context, dynamic user) {
    Widget content;
    
    switch (_selectedMenu) {
      case 'dashboard':
        content = _buildDashboardContent(context, user);
        break;
      case 'schedule':
        content = const CalendarScheduleScreen();
        break;
      case 'patients':
        content = const PatientManagementScreen();
        break;
      case 'makeup':
        content = const MakeupTicketListScreen();
        break;
      case 'voucher':
        content = const VoucherListScreen();
        break;
      case 'payment':
        content = const PaymentListScreen();
        break;
      case 'notice':
        content = const NoticeListScreen();
        break;
      case 'files':
        content = const FileLibraryScreen();
        break;
      case 'register':
        content = const PatientRegistrationScreen();
        break;
      case 'assessment':
        content = const ClinicalFeaturePatientSelector(featureType: 'assessment');
        break;
      case 'session':
        content = const ClinicalFeaturePatientSelector(featureType: 'session');
        break;
      case 'goals':
        content = const ClinicalFeaturePatientSelector(featureType: 'goals');
        break;
      case 'progress':
        content = const ClinicalFeaturePatientSelector(featureType: 'progress');
        break;
      case 'settings':
        content = const AdminSettingsScreen();
        break;
      case 'invites':
        content = const InviteManagementScreen();
        break;
      
      // ========================================
      // 오늘 할 일 (Daily Ops) 화면들
      // ========================================
      case 'today_schedule':
        content = _buildTodaySchedule(context, user);
        break;
      case 'attendance':
        content = _buildAttendanceScreen(context, user);
        break;
      case 'today_session':
        content = _buildTodaySessionScreen(context, user);
        break;
      case 'today_notice':
        content = _buildTodayNoticeScreen(context, user);
        break;
      
      // ========================================
      // 임상 관리 추가 화면
      // ========================================
      case 'content':
        content = _buildContentRecommendation(context, user);
        break;
        
      default:
        content = _buildDashboardContent(context, user);
    }

    return content;
  }

  Widget _buildFeatureComingSoon(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '$title 기능',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '환자를 먼저 선택해주세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 오늘 할 일 (Daily Ops) 화면들
  // ========================================
  
  /// 오늘 일정 화면 (일정 관리의 오늘 날짜로 필터링)
  Widget _buildTodaySchedule(BuildContext context, dynamic user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.today, color: Colors.orange),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 일정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Expanded(
          child: CalendarScheduleScreen(),
        ),
      ],
    );
  }

  /// 출석/수업 처리 화면
  Widget _buildAttendanceScreen(BuildContext context, dynamic user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 100,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 24),
          Text(
            '출석/수업 처리',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 일정에서 출석 처리를 진행하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedMenu = 'today_schedule';
              });
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('오늘 일정으로 이동'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// 오늘 세션 기록 화면
  Widget _buildTodaySessionScreen(BuildContext context, dynamic user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                '오늘 세션 기록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: ClinicalFeaturePatientSelector(featureType: 'session'),
        ),
      ],
    );
  }

  /// 오늘 알림 화면
  Widget _buildTodayNoticeScreen(BuildContext context, dynamic user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                '오늘의 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: NoticeListScreen(),
        ),
      ],
    );
  }

  // ========================================
  // 임상 관리 추가 화면
  // ========================================
  
  /// 콘텐츠 추천 화면
  Widget _buildContentRecommendation(BuildContext context, dynamic user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 100,
            color: Colors.green[400],
          ),
          const SizedBox(height: 24),
          Text(
            '콘텐츠 추천',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '환자의 목표와 평가 결과를 기반으로\n맞춤 콘텐츠를 추천합니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedMenu = 'goals';
              });
            },
            icon: const Icon(Icons.flag),
            label: const Text('목표 관리로 이동'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 환영 카드
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '안녕하세요, ${user.name} 치료사님 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '오늘도 환자들의 회복을 위해 힘써주셔서 감사합니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 통계 카드
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                icon: Icons.calendar_today,
                title: '오늘 예약',
                value: '8',
                color: Colors.blue,
                subtitle: '2건 승인 대기',
              ),
              _buildStatCard(
                icon: Icons.people,
                title: '총 환자',
                value: '24',
                color: Colors.green,
                subtitle: '이번 달 +3명',
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                title: '출석 완료',
                value: '5',
                color: Colors.orange,
                subtitle: '오늘 진행',
              ),
              _buildStatCard(
                icon: Icons.payments,
                title: '오늘 수납',
                value: '450,000원',
                color: Colors.purple,
                subtitle: '5건 처리',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 빠른 액션 버튼
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.add_circle,
                  title: '새 예약 등록',
                  color: Colors.blue,
                  onTap: () {
                    setState(() {
                      _selectedMenu = 'schedule';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.person_add,
                  title: '환자 등록',
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _selectedMenu = 'register';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.edit_note,
                  title: '세션 기록',
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      _selectedMenu = 'session';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.assessment,
                  title: '평가 입력',
                  color: Colors.purple,
                  onTap: () {
                    setState(() {
                      _selectedMenu = 'assessment';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// 공통 위젯들
Widget _buildWelcomeCard(BuildContext context, dynamic user) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요, ${user.name} 치료사님',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '오늘도 환자들의 회복을 위해 힘써주셔서 감사합니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

Widget _buildOperationsSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '📊 운영 관리',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: [
          _buildFeatureCard(
            context,
            icon: Icons.calendar_today,
            title: '일정 관리',
            subtitle: '예약 및 출석',
            color: Colors.blue,
            screen: const CalendarScheduleScreen(),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.people,
            title: '이용자 관리',
            subtitle: '환자 목록',
            color: Colors.green,
            screen: const PatientManagementScreen(),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.confirmation_number,
            title: '보강권 조회',
            subtitle: '보강권 관리',
            color: Colors.orange,
            screen: const MakeupTicketListScreen(),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.card_giftcard,
            title: '바우처 관리',
            subtitle: '바우처 현황',
            color: Colors.purple,
            screen: const VoucherListScreen(),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.payments,
            title: '수납 관리',
            subtitle: '수납/정산',
            color: Colors.indigo,
            screen: const PaymentListScreen(),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.campaign,
            title: '공지사항',
            subtitle: '센터 공지',
            color: Colors.red,
            screen: const NoticeListScreen(),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.folder,
            title: '자료실',
            subtitle: '파일 관리',
            color: Colors.teal,
            screen: const FileLibraryScreen(),
          ),
        ],
      ),
    ],
  );
}

Widget _buildClinicalSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '🏥 임상 기능',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: [
          _buildFeatureCard(
            context,
            icon: Icons.person_add,
            title: '환자 등록',
            subtitle: '신규 등록',
            color: Colors.blue,
            screen: const PatientRegistrationScreen(),
          ),
        ],
      ),
    ],
  );
}

Widget _buildFeatureCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required Widget screen,
}) {
  return Card(
    elevation: 2,
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
