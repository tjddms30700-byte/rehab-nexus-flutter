import 'package:flutter/material.dart';

/// 초간단 세션 기록 화면 (테스트용)
class SimpleSessionRecordScreen extends StatelessWidget {
  const SimpleSessionRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('세션 기록 (테스트)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '✅ 세션 기록 화면이 정상 표시됩니다!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('버튼이 작동합니다!')),
                );
              },
              child: const Text('테스트 버튼'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('뒤로 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
