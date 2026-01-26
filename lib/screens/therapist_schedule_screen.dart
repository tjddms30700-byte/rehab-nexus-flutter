import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/attendance.dart';
import '../services/appointment_service.dart';
import '../services/attendance_service.dart';
import '../providers/app_state.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

/// 치료사 일정 관리 화면
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
  List<Appointment> _todayAppointments = [];
  List<Attendance> _todayAttendances = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🟢 [TherapistScheduleScreen] initState 호출됨');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟡 [TherapistScheduleScreen] addPostFrameCallback 실행');
      _loadTodaySchedule();
    });
  }

  Future<void> _loadTodaySchedule() async {
    print('🔵 [TherapistScheduleScreen] _loadTodaySchedule 시작');
    
    // ✅ mounted 체크 추가
    if (!mounted) {
      print('❌ [TherapistScheduleScreen] mounted=false, 종료');
      return;
    }
    
    final appState = context.read<AppState>();
    final currentUser = appState.currentUser;
    print('🟢 [TherapistScheduleScreen] currentUser: ${currentUser?.name ?? "null"}');

    if (currentUser == null) {
      print('❌ [TherapistScheduleScreen] currentUser가 null, 종료');
      return;
    }

    // ✅ mounted 체크 후 setState
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      print('📝 [TherapistScheduleScreen] Mock 데이터 생성 시작');
      // Mock 데이터 생성 (Firebase 연결 전)
      _todayAppointments = _generateMockAppointments(currentUser.id);
      _todayAttendances = _generateMockAttendances(currentUser.id);
      print('✅ [TherapistScheduleScreen] Mock 데이터 생성 완료: 예약 ${_todayAppointments.length}건, 출석 ${_todayAttendances.length}건');

      // ✅ mounted 체크 후 setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print('✅ [TherapistScheduleScreen] setState 완료, 화면 렌더링 시작');
    } catch (e) {
      print('❌ [TherapistScheduleScreen] 오류 발생: $e');
      print('❌ [TherapistScheduleScreen] Stack trace: ${StackTrace.current}');
      // ✅ mounted 체크 후 setState 및 SnackBar
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🏁 [TherapistScheduleScreen] _loadTodaySchedule 완료');
  }

  List<Appointment> _generateMockAppointments(String therapistId) {
    final now = DateTime.now();
    return [
      Appointment(
        id: 'apt_001',
        patientId: 'patient_001',
        patientName: '홍길동',
        guardianId: 'guardian_001',
        therapistId: therapistId,
        therapistName: '김치료',
        appointmentDate: DateTime(now.year, now.month, now.day, 10, 0),
        timeSlot: '10:00-11:00',
        status: AppointmentStatus.confirmed,
        notes: '수중 보행 훈련 요청',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Appointment(
        id: 'apt_002',
        patientId: 'patient_002',
        patientName: '김영희',
        guardianId: 'guardian_002',
        therapistId: therapistId,
        therapistName: '김치료',
        appointmentDate: DateTime(now.year, now.month, now.day, 14, 0),
        timeSlot: '14:00-15:00',
        status: AppointmentStatus.confirmed,
        notes: '균형 감각 개선 필요',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Appointment(
        id: 'apt_003',
        patientId: 'patient_003',
        patientName: '이철수',
        guardianId: 'guardian_003',
        therapistId: therapistId,
        therapistName: '김치료',
        appointmentDate: DateTime(now.year, now.month, now.day, 16, 0),
        timeSlot: '16:00-17:00',
        status: AppointmentStatus.pending,
        notes: null,
        createdAt: now,
      ),
    ];
  }

  List<Attendance> _generateMockAttendances(String therapistId) {
    final now = DateTime.now();
    return [
      Attendance(
        id: 'att_001',
        patientId: 'patient_001',
        patientName: '홍길동',
        sessionId: 'session_001',
        scheduleDate: DateTime(now.year, now.month, now.day, 10, 0),
        timeSlot: '10:00-11:00',
        status: AttendanceStatus.present,
        therapistId: therapistId,
        therapistName: '김치료',
        createdAt: now,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [TherapistScheduleScreen] build 호출: _isLoading=$_isLoading, 예약=${_todayAppointments.length}건');
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 선택
                    _buildDateSelector(),
                    const SizedBox(height: 24),

                    // 오늘 일정 요약
                    _buildTodaySummary(),
                    const SizedBox(height: 24),

                    // 예약 목록
                    _buildAppointmentList(),
                    const SizedBox(height: 24),

                    // 출석 현황
                    _buildAttendanceList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A0077BE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE', 'ko_KR').format(_selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('날짜 선택'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    final confirmedCount = _todayAppointments
        .where((apt) => apt.status == AppointmentStatus.confirmed)
        .length;
    final pendingCount = _todayAppointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .length;
    final presentCount = _todayAttendances
        .where((att) => att.status == AttendanceStatus.present)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 오늘 일정 요약',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  '예약 확정',
                  confirmedCount.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  '승인 대기',
                  pendingCount.toString(),
                  Colors.orange,
                ),
                _buildSummaryItem(
                  '출석 완료',
                  presentCount.toString(),
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 예약 목록',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_todayAppointments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '오늘 예약이 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ..._todayAppointments.map((appointment) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(appointment.status),
                  child: Text(
                    appointment.patientName[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  appointment.patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🕐 ${appointment.timeSlot}'),
                    if (appointment.notes != null)
                      Text('📝 ${appointment.notes}'),
                  ],
                ),
                trailing: _buildStatusChip(appointment.status),
                onTap: () => _showAppointmentDetail(appointment),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✅ 출석 현황',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_todayAttendances.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '출석 기록이 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ..._todayAttendances.map((attendance) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  _getAttendanceIcon(attendance.status),
                  color: _getAttendanceColor(attendance.status),
                  size: 32,
                ),
                title: Text(
                  attendance.patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('🕐 ${attendance.timeSlot}'),
                trailing: Chip(
                  label: Text(attendance.statusText),
                  backgroundColor: _getAttendanceColor(attendance.status)
                      .withValues(alpha: 0.2),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    final color = _getStatusColor(status);
    final text = status == AppointmentStatus.confirmed
        ? '확정'
        : status == AppointmentStatus.pending
            ? '대기'
            : '취소';

    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.green;
    }
  }

  IconData _getAttendanceIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.cancelled:
        return Icons.event_busy;
      case AttendanceStatus.makeup:
        return Icons.event_repeat;
    }
  }

  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.cancelled:
        return Colors.grey;
      case AttendanceStatus.makeup:
        return Colors.blue;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadTodaySchedule();
    }
  }

  void _showAppointmentDetail(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('예약 상세: ${appointment.patientName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🕐 시간: ${appointment.timeSlot}'),
            const SizedBox(height: 8),
            Text('📅 날짜: ${DateFormat('yyyy-MM-dd').format(appointment.appointmentDate)}'),
            const SizedBox(height: 8),
            Text('📌 상태: ${appointment.statusText}'),
            if (appointment.notes != null) ...[
              const SizedBox(height: 8),
              Text('📝 메모: ${appointment.notes}'),
            ],
          ],
        ),
        actions: [
          if (appointment.status == AppointmentStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _approveAppointment(appointment);
              },
              child: const Text('승인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectAppointment(appointment);
              },
              child: const Text('거절', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _approveAppointment(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${appointment.patientName}님의 예약을 승인했습니다!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    _loadTodaySchedule();
  }

  void _rejectAppointment(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${appointment.patientName}님의 예약을 거절했습니다'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
    _loadTodaySchedule();
  }
}
