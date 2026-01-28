import 'package:flutter/material.dart';

/// 직원 관리 화면 (간단 버전)
class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('직원 관리 (추후 구현)', style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }
}
