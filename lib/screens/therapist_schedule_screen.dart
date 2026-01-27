import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/attendance.dart';
import '../services/appointment_service.dart';
import '../services/attendance_service.dart';
import '../providers/app_state.dart';
import '../constants/enums.dart';

/// 치료사 일정 관리 화면 - Firebase 연동
class TherapistScheduleScreen extends StatefulWidget {
  const TherapistScheduleScreen({Key? key}) : super(key: key);

  @override
  State<TherapistScheduleScreen> createState() =>
      _TherapistScheduleScreenState();
}

class _TherapistScheduleScreenState extends State<TherapistScheduleScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AttendanceService _attendanceService = AttendanceService();

  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  List<Attendance> _attendances = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser;

      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      print('🔵 [일정관리] Firebase에서 예약 데이터 조회 시작...');
      
      // Firebase에서 모든 예약 조회 (단순 쿼리)
      final allAppointments = await _appointmentService.getAppointmentsByTherapist(user.id);
      print('✅ [일정관리] 예약 데이터 조회 완료: ${allAppointments.length}건');
      
      // 오늘 날짜 계산
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      // 앱에서 날짜 필터링 (오늘 예약만)
      final todayAppointments = allAppointments.where((apt) {
        final aptDate = DateTime(
          apt.appointmentDate.year,
          apt.appointmentDate.month,
          apt.appointmentDate.day,
        );
        return aptDate.year == today.year &&
               aptDate.month == today.month &&
               aptDate.day == today.day;
      }).toList();
      
      print('🔵 [일정관리] 오늘 예약: ${todayAppointments.length}건');

      // 출석 데이터 조회 (실패해도 계속 진행)
      List<Attendance> allAttendances = [];
      try {
        print('🔵 [일정관리] Firebase에서 출석 데이터 조회 시작...');
        allAttendances = await _attendanceService.getAttendancesByTherapist(
          user.id,
          today,
          tomorrow,
        );
        print('✅ [일정관리] 출석 데이터 조회 완료: ${allAttendances.length}건');
      } catch (e) {
        print('⚠️ [일정관리] 출석 데이터 조회 실패 (무시하고 계속): $e');
        // 출석 데이터 없어도 계속 진행
      }

      if (!mounted) return;

      setState(() {
        _appointments = todayAppointments;
        _attendances = allAttendances;
        _isLoading = false;
      });

      print('✅ [일정관리] 데이터 로드 완료: 예약 ${_appointments.length}건, 출석 ${_attendances.length}건');
    } catch (e) {
      print('❌ [일정관리] 데이터 로드 실패: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Firebase 연결 오류\n\n오류 내용: ${e.toString()}\n\n새로고침 버튼을 눌러 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜 표시
                      _buildDateCard(),
                      const SizedBox(height: 24),

                      // 오늘 일정 요약
                      _buildSummarySection(),
                      const SizedBox(height: 24),

                      // 예약 목록
                      _buildAppointmentsSection(),
                      const SizedBox(height: 24),

                      // 출석 현황
                      _buildAttendancesSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('선택된 날짜', style: TextStyle(fontSize: 12)),
                Text(
                  DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final confirmedCount = _appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .length;
    final pendingCount = _appointments
        .where((a) => a.status == AppointmentStatus.pending)
        .length;
    final presentCount = _attendances
        .where((a) => a.status == AttendanceStatus.present)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 오늘 일정 요약',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '예약 확정',
                confirmedCount.toString(),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                '승인 대기',
                pendingCount.toString(),
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                '출석 완료',
                presentCount.toString(),
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 예약 목록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_appointments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('오늘 예약이 없습니다'),
                  ],
                ),
              ),
            ),
          )
        else
          ..._appointments.map((appointment) => _buildAppointmentCard(appointment)),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor = appointment.status == AppointmentStatus.confirmed
        ? Colors.blue
        : appointment.status == AppointmentStatus.pending
            ? Colors.orange
            : Colors.grey;

    String statusText = appointment.status == AppointmentStatus.confirmed
        ? '확정'
        : appointment.status == AppointmentStatus.pending
            ? '승인 대기'
            : '취소됨';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(
          appointment.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⏰ ${appointment.timeSlot}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Text('📝 ${appointment.notes}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        isThreeLine: appointment.notes != null && appointment.notes!.isNotEmpty,
      ),
    );
  }

  Widget _buildAttendancesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✅ 출석 현황',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_attendances.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('출석 기록이 없습니다'),
                  ],
                ),
              ),
            ),
          )
        else
          ..._attendances.map((attendance) => _buildAttendanceCard(attendance)),
      ],
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
    Color statusColor = attendance.status == AttendanceStatus.present
        ? Colors.green
        : attendance.status == AttendanceStatus.absent
            ? Colors.red
            : Colors.orange;

    String statusText = attendance.status == AttendanceStatus.present
        ? '출석'
        : attendance.status == AttendanceStatus.absent
            ? '결석'
            : '취소';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.check_circle, color: statusColor),
        ),
        title: Text(
          attendance.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⏰ ${attendance.timeSlot}'),
            if (attendance.cancelReason != null && attendance.cancelReason!.isNotEmpty)
              Text('📝 ${attendance.cancelReason}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
