import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/attendance.dart';
import '../models/makeup_ticket.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

/// 치료사 일정 관리 화면 (완전 재작성)
class TherapistScheduleScreen extends StatefulWidget {
  const TherapistScheduleScreen({Key? key}) : super(key: key);

  @override
  State<TherapistScheduleScreen> createState() =>
      _TherapistScheduleScreenState();
}

class _TherapistScheduleScreenState extends State<TherapistScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  List<Attendance> _attendances = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() {
    setState(() {
      _isLoading = true;
    });

    // Mock 데이터 생성
    final now = DateTime.now();
    _appointments = [
      Appointment(
        id: 'apt_001',
        patientId: 'patient_001',
        patientName: '홍길동',
        guardianId: 'guardian_001',
        therapistId: 'therapist_001',
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
        therapistId: 'therapist_001',
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
        therapistId: 'therapist_001',
        therapistName: '김치료',
        appointmentDate: DateTime(now.year, now.month, now.day, 16, 0),
        timeSlot: '16:00-17:00',
        status: AppointmentStatus.pending,
        notes: null,
        createdAt: now,
      ),
    ];

    _attendances = [
      Attendance(
        id: 'att_001',
        patientId: 'patient_001',
        patientName: '홍길동',
        sessionId: 'session_001',
        scheduleDate: DateTime(now.year, now.month, now.day, 10, 0),
        timeSlot: '10:00-11:00',
        status: AttendanceStatus.present,
        therapistId: 'therapist_001',
        therapistName: '김치료',
        createdAt: now,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    _buildSummary(),
                    const SizedBox(height: 24),
                    _buildAppointmentSection(),
                    const SizedBox(height: 24),
                    _buildAttendanceSection(),
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
                DateFormat('EEEE').format(_selectedDate), // locale 제거
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

  Widget _buildSummary() {
    final confirmed = _appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .length;
    final pending =
        _appointments.where((a) => a.status == AppointmentStatus.pending).length;
    final present = _attendances
        .where((a) => a.status == AttendanceStatus.present)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 오늘 일정 요약',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('예약 확정', '$confirmed', Colors.blue),
                _buildSummaryItem('승인 대기', '$pending', Colors.orange),
                _buildSummaryItem('출석 완료', '$present', Colors.green),
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAppointmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 예약 목록',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_appointments.isEmpty)
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
          ..._appointments.map((apt) => _buildAppointmentCard(apt)).toList(),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
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
            if (appointment.notes != null) Text('📝 ${appointment.notes}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            _getStatusText(appointment.status),
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: _getStatusColor(appointment.status),
        ),
        onTap: () => _showAppointmentDetail(appointment),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '✅ 출석 현황',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _showAttendanceCheck,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('출석 체크'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_attendances.isEmpty)
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
          ..._attendances.map((att) => _buildAttendanceCard(att)).toList(),
      ],
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
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
          label: Text(_getAttendanceText(attendance.status)),
          backgroundColor:
              _getAttendanceColor(attendance.status).withValues(alpha: 0.2),
        ),
      ),
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

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return '확정';
      case AppointmentStatus.pending:
        return '대기';
      case AppointmentStatus.cancelled:
        return '취소';
      case AppointmentStatus.completed:
        return '완료';
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

  String _getAttendanceText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '출석';
      case AttendanceStatus.absent:
        return '결석';
      case AttendanceStatus.cancelled:
        return '취소';
      case AttendanceStatus.makeup:
        return '보강';
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
      _loadSchedule();
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
            Text(
                '📅 날짜: ${DateFormat('yyyy-MM-dd').format(appointment.appointmentDate)}'),
            const SizedBox(height: 8),
            Text('📌 상태: ${_getStatusText(appointment.status)}'),
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
    setState(() {
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment.copyWith(
          status: AppointmentStatus.confirmed,
          updatedAt: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${appointment.patientName}님의 예약을 승인했습니다!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _rejectAppointment(Appointment appointment) {
    setState(() {
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment.copyWith(
          status: AppointmentStatus.cancelled,
          updatedAt: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${appointment.patientName}님의 예약을 거절했습니다'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAttendanceCheck() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출석 체크'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘 예약된 환자의 출석 상태를 선택하세요:'),
            const SizedBox(height: 16),
            ..._appointments
                .where((a) => a.status == AppointmentStatus.confirmed)
                .map((apt) => ListTile(
                      title: Text(apt.patientName),
                      subtitle: Text(apt.timeSlot),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () {
                              Navigator.pop(context);
                              _markAttendance(apt, AttendanceStatus.present);
                            },
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              _markAttendance(apt, AttendanceStatus.absent);
                            },
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _markAttendance(Appointment appointment, AttendanceStatus status) {
    final now = DateTime.now();
    final newAttendance = Attendance(
      id: 'att_${now.millisecondsSinceEpoch}',
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      sessionId: 'session_${now.millisecondsSinceEpoch}',
      scheduleDate: appointment.appointmentDate,
      timeSlot: appointment.timeSlot,
      status: status,
      therapistId: appointment.therapistId,
      therapistName: appointment.therapistName,
      createdAt: now,
    );

    setState(() {
      _attendances.add(newAttendance);
    });

    // 결석인 경우 보강권 발급 제안
    if (status == AttendanceStatus.absent) {
      _showMakeupTicketDialog(appointment, newAttendance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ ${appointment.patientName}님 출석 처리 완료 (${_getAttendanceText(status)})'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMakeupTicketDialog(
      Appointment appointment, Attendance attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보강권 발급'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appointment.patientName}님이 결석하였습니다.'),
            const SizedBox(height: 16),
            const Text('보강권을 발급하시겠습니까?'),
            const SizedBox(height: 8),
            const Text(
              '보강권 유효기간: 30일',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _issueMakeupTicket(appointment, attendance);
            },
            child: const Text('발급'),
          ),
        ],
      ),
    );
  }

  void _issueMakeupTicket(Appointment appointment, Attendance attendance) {
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(days: 30));

    final ticket = MakeupTicket(
      id: 'makeup_${now.millisecondsSinceEpoch}',
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      originalAttendanceId: attendance.id,
      originalDate: appointment.appointmentDate,
      originalTimeSlot: appointment.timeSlot,
      status: MakeupTicketStatus.available,
      expiryDate: expiryDate,
      therapistId: appointment.therapistId,
      therapistName: appointment.therapistName,
      notes: '결석으로 인한 보강권 발급',
      createdAt: now,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ ${appointment.patientName}님 보강권 발급 완료!\n유효기간: ${DateFormat('yyyy-MM-dd').format(expiryDate)}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
