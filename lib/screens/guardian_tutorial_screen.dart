import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'guardian_home_screen.dart';

/// 보호자용 첫 진입 안내 (1페이지 튜토리얼)
/// 
/// 원칙: 1페이지 + 3문장 + 아이콘
/// - 스와이프 비활성
/// - Skip 버튼 없음
/// - "시작하기" 버튼으로 진행
class GuardianTutorialScreen extends StatelessWidget {
  const GuardianTutorialScreen({super.key});

  Future<void> _completeTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guardian_tutorial_completed', true);
    
    if (context.mounted) {
      final appState = context.read<AppState>();
      final user = appState.currentUser;
      
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GuardianHomeScreen(user: user),
          ),
        );
      } else {
        // 사용자 정보가 없으면 로그인 화면으로
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 로고 영역
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.waves,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 32),

              // 환영 문구
              const Text(
                'AQU LAB Care에\n오신 것을 환영합니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 48),

              // 기능 안내 (3개)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.calendar_today,
                      iconColor: const Color(0xFF2196F3),
                      title: '수업 일정 확인',
                      description: '아이의 수업 일정과 변경 요청을 확인할 수 있어요',
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureItem(
                      icon: Icons.description,
                      iconColor: const Color(0xFF4CAF50),
                      title: '치료 리포트 열람',
                      description: '수업 후 치료 요약과 변화를 확인하세요',
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureItem(
                      icon: Icons.home,
                      iconColor: const Color(0xFFFF9800),
                      title: '가정 연계 활동',
                      description: '집에서 도와줄 수 있는 활동을 안내해드려요',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _completeTutorial(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

              // 보조 문구
              Text(
                '이 안내는 언제든 다시 볼 수 있어요',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF666666).withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 8),
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
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),

        const SizedBox(width: 16),

        // 텍스트
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
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
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

/// 튜토리얼 완료 여부 확인 헬퍼
class GuardianTutorialHelper {
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('guardian_tutorial_completed') ?? false;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guardian_tutorial_completed');
  }
}
