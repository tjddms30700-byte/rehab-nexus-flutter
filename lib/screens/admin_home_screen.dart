import 'package:flutter/material.dart';

/// 관리자 홈 화면
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AQU LAB Care - 관리자'),
      ),
      body: const Center(
        child: Text('관리자 홈 화면 (구현 예정)'),
      ),
    );
  }
}
