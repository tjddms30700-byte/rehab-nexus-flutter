import 'package:flutter/material.dart';

/// 일정 관리 화면 (디버그 - 초간단 버전)
class TherapistScheduleScreen extends StatelessWidget {
  const TherapistScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔵 TherapistScheduleScreen: build called');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 관리 - 테스트'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                '일정 관리 화면',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '이 화면이 보이면 정상입니다!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  print('🟢 테스트 버튼 클릭');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 테스트 성공!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('테스트 버튼'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
