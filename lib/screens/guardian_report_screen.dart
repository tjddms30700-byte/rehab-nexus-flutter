import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../constants/app_theme.dart';

/// 보호자용 치료 리포트 화면 - 간단 버전
class GuardianReportScreen extends StatelessWidget {
  final Patient patient;

  const GuardianReportScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('치료 리포트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📄 PDF 다운로드 기능\n💡 모바일 앱에서 사용 가능합니다'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            tooltip: 'PDF 다운로드',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 환자 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    radius: 30,
                    child: Text(
                      patient.name.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('${patient.age}세'),
                        Text(
                          patient.diagnosis.join(', '),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 최근 평가 결과
          const Text(
            '최근 평가 결과',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

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
                      const Text(
                        '총점',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '52 / 105점',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 52 / 105,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text('49% (Level 2 - 초급)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 강점
          const Text(
            '✓ 강점',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• 활동 참여도 우수'),
                  SizedBox(height: 4),
                  Text('• 치료사 협조 양호'),
                  SizedBox(height: 4),
                  Text('• 호흡 조절 가능'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 개선 필요
          const Text(
            '⚠ 개선 필요 영역',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• 한 발 서기 어려움'),
                  SizedBox(height: 4),
                  Text('• 물속 보행 불안정'),
                  SizedBox(height: 4),
                  Text('• 팔다리 협응 미흡'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 최근 세션 기록
          const Text(
            '최근 세션 기록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildSessionCard('1회차', '2026-01-24', '물속 균형 잡기, 호흡 조절', '😊'),
          _buildSessionCard('2회차', '2026-01-27', '팔 운동, 다리 운동', '😐'),
          _buildSessionCard('3회차', '2026-01-29', '균형 훈련, 협응 훈련', '😊'),
          const SizedBox(height: 24),

          // 치료사 소견
          const Text(
            '치료사 소견',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            color: const Color(0x1A2196F3), // AppTheme.info with 10% opacity
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '환자는 지속적인 치료를 통해 균형 감각과 근력이 향상되고 있습니다. '
                '특히 참여도가 높아 치료 효과가 좋습니다. '
                '가정에서도 꾸준한 운동을 실천하시면 더 빠른 회복이 가능할 것으로 예상됩니다.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(String session, String date, String activities, String mood) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary,
          child: Text(
            session.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(session),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date),
            Text(
              activities,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          mood,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
