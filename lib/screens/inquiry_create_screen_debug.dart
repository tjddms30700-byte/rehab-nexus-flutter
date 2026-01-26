import 'package:flutter/material.dart';
import '../models/patient.dart';

/// 문의하기 화면 (디버그 - 초간단 버전)
class InquiryCreateScreen extends StatelessWidget {
  final Patient patient;

  const InquiryCreateScreen({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔵 InquiryCreateScreen: build called for patient: ${patient.name}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기 - 테스트'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.help,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                '${patient.name}님의 문의하기',
                style: const TextStyle(
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
                  print('🟢 문의 테스트 버튼 클릭');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 문의 테스트 성공!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
