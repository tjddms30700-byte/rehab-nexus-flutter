import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/attendance.dart';
import '../models/makeup_ticket.dart';
import '../services/appointment_service.dart';
import '../services/attendance_service.dart';
import '../services/makeup_ticket_service.dart';
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
  final MakeupTicketService _makeupTicketService = MakeupTicketService();

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
      child: ExpansionTile(
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
        children: [
          // 예약 상세 정보 및 액션 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 예약 정보
                _buildInfoRow('환자명', appointment.patientName),
                _buildInfoRow('시간', appointment.timeSlot),
                _buildInfoRow('예약일', DateFormat('yyyy-MM-dd').format(appointment.appointmentDate)),
                if (appointment.notes != null && appointment.notes!.isNotEmpty)
                  _buildInfoRow('요청사항', appointment.notes!),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // 액션 버튼 (승인 대기 상태일 때만 표시)
                if (appointment.status == AppointmentStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmAppointment(appointment),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('승인'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectAppointment(appointment),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('거절'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                // 확정 상태일 때 취소 버튼
                if (appointment.status == AppointmentStatus.confirmed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('예약 취소'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // 예약 승인
  Future<void> _confirmAppointment(Appointment appointment) async {
    try {
      // 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약 승인'),
          content: Text('${appointment.patientName} 환자의 예약을 승인하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('승인'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Firebase에 예약 승인 요청
      setState(() => _isLoading = true);
      await _appointmentService.confirmAppointment(appointment.id);
      
      // 데이터 새로고침
      await _loadData();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 예약이 승인되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ 예약 승인 실패: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('예약 승인 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // 예약 거절
  Future<void> _rejectAppointment(Appointment appointment) async {
    try {
      // 거절 사유 입력 다이얼로그
      final TextEditingController reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약 거절'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${appointment.patientName} 환자의 예약을 거절하시겠습니까?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: '거절 사유 (선택)',
                  border: OutlineInputBorder(),
                  hintText: '예: 해당 시간대 예약 불가',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('거절'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Firebase에 예약 취소 요청
      setState(() => _isLoading = true);
      await _appointmentService.cancelAppointment(appointment.id);
      
      // 데이터 새로고침
      await _loadData();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약이 거절되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ 예약 거절 실패: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('예약 거절 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // 예약 취소
  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      // 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약 취소'),
          content: Text('${appointment.patientName} 환자의 예약을 취소하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('아니오'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('예, 취소합니다'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Firebase에 예약 취소 요청
      setState(() => _isLoading = true);
      await _appointmentService.cancelAppointment(appointment.id);
      
      // 데이터 새로고침
      await _loadData();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약이 취소되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ 예약 취소 실패: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('예약 취소 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
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
      child: ExpansionTile(
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
        children: [
          // 출석 상세 정보 및 상태 변경 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 출석 정보
                _buildInfoRow('환자명', attendance.patientName),
                _buildInfoRow('시간', attendance.timeSlot),
                _buildInfoRow('일정일', DateFormat('yyyy-MM-dd').format(attendance.scheduleDate)),
                _buildInfoRow('현재 상태', statusText),
                if (attendance.cancelReason != null && attendance.cancelReason!.isNotEmpty)
                  _buildInfoRow('비고', attendance.cancelReason!),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // 출석 상태 변경 버튼
                const Text(
                  '출석 상태 변경',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: attendance.status == AttendanceStatus.present
                            ? null
                            : () => _updateAttendanceStatus(
                                attendance,
                                AttendanceStatus.present,
                              ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('출석'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: attendance.status == AttendanceStatus.absent
                            ? null
                            : () => _updateAttendanceStatus(
                                attendance,
                                AttendanceStatus.absent,
                              ),
                        icon: const Icon(Icons.cancel),
                        label: const Text('결석'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: attendance.status == AttendanceStatus.cancelled
                            ? null
                            : () => _updateAttendanceStatus(
                                attendance,
                                AttendanceStatus.cancelled,
                              ),
                        icon: const Icon(Icons.event_busy),
                        label: const Text('취소'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 출석 상태 업데이트
  Future<void> _updateAttendanceStatus(
    Attendance attendance,
    AttendanceStatus newStatus,
  ) async {
    try {
      String statusText = newStatus == AttendanceStatus.present
          ? '출석'
          : newStatus == AttendanceStatus.absent
              ? '결석'
              : '취소';

      // 확인 다이얼로그
      String? cancelReason;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final TextEditingController reasonController = TextEditingController();
          return AlertDialog(
            title: Text('출석 상태 변경: $statusText'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${attendance.patientName} 환자의 출석 상태를 "$statusText"(으)로 변경하시겠습니까?'),
                if (newStatus != AttendanceStatus.present) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: newStatus == AttendanceStatus.absent ? '결석 사유' : '취소 사유',
                      border: const OutlineInputBorder(),
                      hintText: '사유를 입력해주세요 (선택)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  cancelReason = reasonController.text.trim();
                  Navigator.pop(context, true);
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // Firebase에 출석 상태 업데이트
      setState(() => _isLoading = true);
      await _attendanceService.updateAttendanceStatus(
        attendance.id,
        newStatus,
        cancelReason: cancelReason?.isNotEmpty == true ? cancelReason : null,
      );
      
      // 결석 또는 취소 시 보강권 자동 발급
      if (newStatus == AttendanceStatus.absent || newStatus == AttendanceStatus.cancelled) {
        try {
          final appState = context.read<AppState>();
          final user = appState.currentUser;
          
          // 30일 후 만료
          final expiryDate = DateTime.now().add(const Duration(days: 30));
          
          final makeupTicket = MakeupTicket(
            id: '', // Firestore가 자동 생성
            patientId: attendance.patientId,
            patientName: attendance.patientName,
            originalAttendanceId: attendance.id,
            originalDate: attendance.scheduleDate,
            originalTimeSlot: attendance.timeSlot,
            status: MakeupTicketStatus.available,
            expiryDate: expiryDate,
            therapistId: user?.id ?? 'unknown',
            therapistName: user?.name ?? 'Unknown',
            notes: newStatus == AttendanceStatus.absent 
                ? '결석으로 인한 보강권 발급' 
                : '취소로 인한 보강권 발급',
            createdAt: DateTime.now(),
          );
          
          await _makeupTicketService.createMakeupTicket(makeupTicket);
          print('✅ 보강권 자동 발급 완료');
        } catch (e) {
          print('⚠️ 보강권 발급 실패 (무시): $e');
          // 보강권 발급 실패해도 출석 상태 변경은 유지
        }
      }
      
      // 데이터 새로고침
      await _loadData();

      if (!mounted) return;
      
      // 보강권 발급 안내 추가
      String message = '✅ 출석 상태가 "$statusText"(으)로 변경되었습니다';
      if (newStatus == AttendanceStatus.absent || newStatus == AttendanceStatus.cancelled) {
        message += '\n🎫 보강권이 자동으로 발급되었습니다 (유효기간: 30일)';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ 출석 상태 변경 실패: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('출석 상태 변경 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }
}
