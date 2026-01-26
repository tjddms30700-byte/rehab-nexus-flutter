import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants/app_theme.dart';
import '../models/patient.dart';
import 'guardian_report_screen.dart';
import 'guardian_home_program_screen.dart';
import 'appointment_request_screen_debug.dart';
import 'inquiry_create_screen_debug.dart';

/// 보호자 홈 화면
class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AQU LAB Care - 보호자'),
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
                    '안녕하세요, ${user.name}님',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아이의 치료 진행 상황을 확인하고, 가정에서의 운동을 함께 해보세요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 기능 버튼
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.analytics,
                title: '치료 리포트',
                subtitle: '세션 기록 및 성과',
                color: AppTheme.primary,
                onTap: () {
                  // 테스트용 샘플 환자
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15),
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: 'therapist_001',
                    createdAt: DateTime.now(),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GuardianReportScreen(
                        patient: samplePatient,
                      ),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.fitness_center,
                title: '홈프로그램',
                subtitle: '가정 운동 과제',
                color: AppTheme.secondary,
                onTap: () {
                  // 테스트용 샘플 환자
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15),
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: 'therapist_001',
                    createdAt: DateTime.now(),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GuardianHomeProgramScreen(
                        patient: samplePatient,
                      ),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.event,
                title: '예약 관리',
                subtitle: '치료 일정 확인',
                color: AppTheme.accent,
                onTap: () {
                  // 테스트용 샘플 환자
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15),
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: 'therapist_001',
                    createdAt: DateTime.now(),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentRequestScreen(
                        patient: samplePatient,
                      ),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.chat,
                title: '문의하기',
                subtitle: '치료사에게 연락',
                color: AppTheme.info,
                onTap: () {
                  // 테스트용 샘플 환자
                  final samplePatient = Patient(
                    id: 'patient_001',
                    organizationId: 'org_001',
                    patientCode: 'P001',
                    name: '홍길동',
                    birthDate: DateTime(2016, 3, 15),
                    gender: 'M',
                    diagnosis: ['발달지연', '균형장애'],
                    assignedTherapistId: 'therapist_001',
                    createdAt: DateTime.now(),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InquiryCreateScreen(
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
