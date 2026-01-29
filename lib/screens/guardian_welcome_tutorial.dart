import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 보호자용 첫 진입 안내 (튜토리얼 1페이지)
/// 규정: 1페이지 + 3문장 + 아이콘
class GuardianWelcomeTutorial extends StatelessWidget {
  const GuardianWelcomeTutorial({super.key});

  static const String _tutorialSeenKey = 'guardian_tutorial_seen';

  /// 튜토리얼을 본 적이 있는지 확인
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialSeenKey) ?? false;
  }

  /// 튜토리얼을 봤다고 표시
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, true);
  }

  /// 튜토리얼을 다시 보기 위해 초기화
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialSeenKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 및 앱명
              Image.asset(
                'assets/app_icon.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 60,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 환영 문구
              const Text(
                'AQU LAB Care에\n오신 것을 환영합니다',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // 3문장 + 아이콘
              _buildFeatureItem(
                icon: Icons.calendar_today,
                iconColor: const Color(0xFF2196F3),
                title: '수업 일정 확인',
                description: '아이의 수업 일정과 변경 요청을 확인할 수 있습니다',
              ),
              const SizedBox(height: 32),
              
              _buildFeatureItem(
                icon: Icons.description,
                iconColor: const Color(0xFF4CAF50),
                title: '치료 리포트 열람',
                description: '치료 요약과 아이의 변화를 확인할 수 있습니다',
              ),
              const SizedBox(height: 32),
              
              _buildFeatureItem(
                icon: Icons.fitness_center,
                iconColor: const Color(0xFFFF9800),
                title: '가정 연계 활동',
                description: '가정에서 아이를 도울 수 있는 활동을 안내합니다',
              ),
              
              const Spacer(),
              
              // 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await markTutorialAsSeen();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 안내 문구
              Text(
                '이 안내는 언제든 다시 볼 수 있어요',
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
