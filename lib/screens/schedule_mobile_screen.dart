// 일정 관리 모바일 최적화 화면
// 세로 타임라인 카드형 UX

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../constants/user_roles.dart';
import '../constants/enums.dart';

class ScheduleMobileScreen extends StatefulWidget {
  final AppUser user;
  
  const ScheduleMobileScreen({super.key, required this.user});
  
  @override
  State<ScheduleMobileScreen> createState() => _ScheduleMobileScreenState();
}

class _ScheduleMobileScreenState extends State<ScheduleMobileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }
  
  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      Query query = _firestore.collection('appointments')
          .where('appointment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointment_date', isLessThan: Timestamp.fromDate(endOfDay));
      
      // 치료사는 자신의 예약만
      if (widget.user.role == UserRole.therapist) {
        query = query.where('therapist_id', isEqualTo: widget.user.id);
      }
      
      final querySnapshot = await query.get();
      
      setState(() {
        _appointments = querySnapshot.docs
            .map((doc) => Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 로드 실패: $e')),
        );
      }
    }
  }
  
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAppointments();
  }
  
  void _showCalendarPicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ).then((picked) {
      if (picked != null && picked != _selectedDate) {
        setState(() => _selectedDate = picked);
        _loadAppointments();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 예약 추가 화면
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('예약 추가 기능 개발 예정')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTimelineList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _changeDate(-1),
          ),
          InkWell(
            onTap: _showCalendarPicker,
            child: Row(
              children: [
                Text(
                  DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineList() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '예약이 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // 시간대별 그룹화 (9시~18시)
    final Map<int, List<Appointment>> appointmentsByHour = {};
    for (var appointment in _appointments) {
      final hour = appointment.appointmentDate.hour;
      if (!appointmentsByHour.containsKey(hour)) {
        appointmentsByHour[hour] = [];
      }
      appointmentsByHour[hour]!.add(appointment);
    }
    
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10, // 9시~18시
        itemBuilder: (context, index) {
          final hour = 9 + index;
          final hourAppointments = appointmentsByHour[hour] ?? [];
          
          if (hourAppointments.isEmpty) {
            return _buildEmptyTimeSlot(hour);
          }
          
          return Column(
            children: hourAppointments.map((appointment) {
              return _buildAppointmentCard(hour, appointment);
            }).toList(),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyTimeSlot(int hour) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[100],
      child: InkWell(
        onTap: () {
          // TODO: 이 시간에 예약 추가
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${hour}:00 예약 추가')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      '비어있음',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppointmentCard(int hour, Appointment appointment) {
    final now = DateTime.now();
    final isPast = appointment.appointmentDate.isBefore(now);
    final isToday = appointment.appointmentDate.day == now.day &&
        appointment.appointmentDate.month == now.month &&
        appointment.appointmentDate.year == now.year;
    
    Color statusColor;
    String statusText;
    List<Widget> actionButtons = [];
    
    if (appointment.status == AppointmentStatus.completed) {
      statusColor = Colors.green;
      statusText = '출석 완료';
      actionButtons = [
        ElevatedButton.icon(
          onPressed: () {
            // TODO: 세션 기록
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('세션 기록 기능 개발 예정')),
            );
          },
          icon: const Icon(Icons.edit_note, size: 18),
          label: const Text('세션 기록'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ];
    } else if (appointment.status == AppointmentStatus.cancelled) {
      statusColor = Colors.red;
      statusText = '취소됨';
    } else if (isPast) {
      statusColor = Colors.orange;
      statusText = '미처리';
      actionButtons = [
        ElevatedButton.icon(
          onPressed: () => _markAttendance(appointment, true),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('출석'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _markAttendance(appointment, false),
          icon: const Icon(Icons.cancel, size: 18),
          label: const Text('결석'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ];
    } else {
      statusColor = Colors.blue;
      statusText = '예정';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간 + 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:${appointment.appointmentDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(height: 24),
            
            // 환자 정보
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    appointment.patientName.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (appointment.therapistName != null)
                        Text(
                          '담당: ${appointment.therapistName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // 메모
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.notes!,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // 액션 버튼
            if (actionButtons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actionButtons,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _markAttendance(Appointment appointment, bool attended) async {
    try {
      await _firestore.collection('appointments').doc(appointment.id).update({
        'status': attended ? 'completed' : 'cancelled',
        'attended': attended,
        'updated_at': Timestamp.now(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attended ? '출석 처리 완료' : '결석 처리 완료'),
          backgroundColor: attended ? Colors.green : Colors.orange,
        ),
      );
      
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 실패: $e')),
      );
    }
  }
}
