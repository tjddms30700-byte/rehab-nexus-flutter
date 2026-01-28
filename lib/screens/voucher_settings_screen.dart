import 'package:flutter/material.dart';

/// 바우처 설정 화면 (간단 버전)
class VoucherSettingsScreen extends StatelessWidget {
  const VoucherSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('바우처 설정 (추후 구현)', style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }
}
