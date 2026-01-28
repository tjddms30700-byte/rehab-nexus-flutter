import 'package:flutter/material.dart';
import '../screens/work_hours_settings_screen.dart';
import '../screens/class_settings_screen.dart';
import '../screens/voucher_settings_screen.dart';
import '../screens/staff_management_screen.dart';

/// 관리자 설정 메인 화면
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환경설정'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '업무시간/휴무'),
            Tab(text: '수업과목설정'),
            Tab(text: '바우처설정'),
            Tab(text: '직원관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WorkHoursSettingsScreen(),
          ClassSettingsScreen(),
          VoucherSettingsScreen(),
          StaffManagementScreen(),
        ],
      ),
    );
  }
}
