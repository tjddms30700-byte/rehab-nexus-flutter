import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants/app_theme.dart';
import '../models/patient.dart';
import 'simple_patient_registration_screen.dart';
import 'patient_registration_screen.dart';
import 'assessment_screen.dart';
import 'session_record_screen.dart';
import 'goal_list_screen.dart';
import 'progress_dashboard_screen.dart';
import 'therapist_schedule_screen_debug.dart';
import 'patient_management_screen.dart';
import 'notice_list_screen.dart';
import 'file_library_screen.dart';
import 'firebase_test_screen.dart';
import 'makeup_ticket_list_screen.dart';
import 'voucher_list_screen.dart';
import 'payment_list_screen.dart';

/// 치료사 홈 화면
class TherapistHomeScreen extends StatelessWidget {
  const TherapistHomeScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 환영 카드
          Card(
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
          ),
          const SizedBox(height: 16),

          // 운영 관리 섹션
          const Text(
            '📊 운영 관리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 운영 관리 기능 버튼
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TherapistScheduleScreen(),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.people,
                title: '이용자 관리',
                subtitle: '환자 목록',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientManagementScreen(),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.notifications,
                title: '공지사항',
                subtitle: '센터 공지',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NoticeListScreen(),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.folder,
                title: '자료실',
                subtitle: '문서 관리',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FileLibraryScreen(),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.card_giftcard,
                title: '보강권 조회',
                subtitle: '이월 관리',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MakeupTicketListScreen(),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.receipt_long,
                title: '바우처 관리',
                subtitle: '바우처 현황',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoucherListScreen(),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.payments,
                title: '수납 관리',
                subtitle: '수납/정산',
                color: Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🔥 Firebase 테스트 섹션
          const Text(
            '🔥 Firebase 연동 테스트',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud, color: Colors.orange, size: 32),
              title: const Text(
                'Firebase 연결 테스트',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Firestore 데이터 저장/조회 테스트'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirebaseTestScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 기능 버튼 (기존 임상 기능)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.person_add,
                title: '환자 등록',
                subtitle: 'Step 1',
                color: AppTheme.primary,
                onTap: () {
                  if (kDebugMode) {
                    print('🟡 환자 등록 버튼 클릭됨');
                  }
                  // 임시로 간단한 화면 사용
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('환자 등록'),
                      content: const Text('환자 등록 기능은 Firebase 연동 후 사용 가능합니다.\n\n현재는 Mock 데이터로 테스트 중입니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.assessment,
                title: '평가 입력',
                subtitle: 'Step 2',
                color: AppTheme.secondary,
                onTap: () async {
                  if (kDebugMode) {
                    print('🟡 평가 입력 버튼 클릭됨');
                  }
                  // 임시로 다이얼로그 표시
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('평가 입력'),
                      content: const Text('평가 입력 기능은 Firebase 연동 후 사용 가능합니다.\n\n현재는 Mock 데이터로 테스트 중입니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.recommend,
                title: '콘텐츠 추천',
                subtitle: 'Step 3',
                color: AppTheme.accent,
                onTap: () async {
                  // 테스트용 샘플 환자 데이터
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15), // 8세
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: user.id,
                    medicalHistory: {
                      'notes': '조산아 출생력, 뇌성마비 경증'
                    },
                    createdAt: DateTime.now(),
                  );
                  
                  await Navigator.pushNamed(
                    context,
                    '/content_recommendation',
                    arguments: samplePatient,
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.edit_note,
                title: '세션 기록',
                subtitle: 'Step 4',
                color: AppTheme.info,
                onTap: () async {
                  // 테스트용 샘플 환자 데이터
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15), // 8세
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: user.id,
                    medicalHistory: {
                      'notes': '조산아 출생력, 뇌성마비 경증'
                    },
                    createdAt: DateTime.now(),
                  );
                  
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionRecordScreen(
                        patient: samplePatient,
                      ),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.flag,
                title: '목표 관리',
                subtitle: 'SMART Goal',
                color: Colors.purple,
                onTap: () async {
                  // 테스트용 샘플 환자 데이터
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15), // 8세
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: user.id,
                    medicalHistory: {
                      'notes': '조산아 출생력, 뇌성마비 경증'
                    },
                    createdAt: DateTime.now(),
                  );
                  
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalListScreen(
                        patient: samplePatient,
                      ),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.show_chart,
                title: '성과추이',
                subtitle: 'Dashboard',
                color: Colors.deepPurple,
                onTap: () async {
                  // 테스트용 샘플 환자 데이터
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15), // 8세
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: user.id,
                    medicalHistory: {
                      'notes': '조산아 출생력, 뇌성마비 경증'
                    },
                    createdAt: DateTime.now(),
                  );
                  
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgressDashboardScreen(
                        patient: samplePatient,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
