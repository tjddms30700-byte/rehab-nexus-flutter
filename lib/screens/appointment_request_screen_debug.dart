import 'package:flutter/material.dart';
import '../models/patient.dart';

/// 예약 관리 화면 (디버그 - 초간단 버전)
class AppointmentRequestScreen extends StatelessWidget {
  final Patient patient;

  const AppointmentRequestScreen({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 관리'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Icon(
                Icons.event,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                '${patient.name}님의 예약',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '정상 표시됩니다!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ 테스트 성공!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('테스트'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
