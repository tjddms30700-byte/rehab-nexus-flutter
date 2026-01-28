import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_state.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../constants/enums.dart';
import '../services/appointment_service.dart';
import '../services/patient_service.dart';

/// 새로운 일정관리 화면 - 캘린더 + 치료사별 시간표
class CalendarScheduleScreen extends StatefulWidget {
  const CalendarScheduleScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScheduleScreen> createState() => _CalendarScheduleScreenState();
}

class _CalendarScheduleScreenState extends State<CalendarScheduleScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final PatientService _patientService = PatientService();

  // 선택된 날짜
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  // 뷰 모드 (일/주/월)
  String _viewMode = '일';

  // 치료사 목록
  List<Map<String, String>> _therapists = [];

  // 예약 데이터
  Map<String, List<Appointment>> _appointmentsByTherapist = {};

  // 환자 목록 (예약 생성용)
  List<Patient> _patients = [];

  // 로딩 상태
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTherapists();
  }

  /// 치료사 목록 로드
  Future<void> _loadTherapists() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'THERAPIST')
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      setState(() {
        _therapists = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': data['id'] as String,
            'name': data['name'] as String,
            'specialty': data['specialty'] as String? ?? 'general',
          };
        }).toList();
      });

      await _loadAppointments();
      await _loadPatients();
    } catch (e) {
      print('❌ 치료사 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 예약 데이터 로드
  Future<void> _loadAppointments() async {
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Map<String, List<Appointment>> appointmentsByTherapist = {};

      for (var therapist in _therapists) {
        final appointments = await _appointmentService.getAppointmentsByDate(
          therapist['id']!,
          _selectedDate,
        );

        appointmentsByTherapist[therapist['id']!] = appointments;
      }

      setState(() {
        _appointmentsByTherapist = appointmentsByTherapist;
        _isLoading = false;
      });

      print('✅ 예약 로드 완료: ${_selectedDate.toString().split(' ')[0]}');
    } catch (e) {
      print('❌ 예약 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 환자 목록 로드
  Future<void> _loadPatients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      setState(() {
        _patients = snapshot.docs.map((doc) {
          return Patient.fromFirestore(doc.data(), doc.id);
        }).toList();
      });

      print('✅ 환자 목록 로드: ${_patients.length}명');
    } catch (e) {
      print('❌ 환자 로드 실패: $e');
    }
  }

  /// 날짜 변경 시
  void _onDateSelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _focusedDate = focusedDate;
      _isLoading = true;
    });
    _loadAppointments();
  }

  /// 시간 슬롯 클릭 시 - 예약 생성 다이얼로그
  Future<void> _onTimeSlotTapped(String therapistId, String therapistName, int hour) async {
    final timeSlot = '${hour.toString().padLeft(2, '0')}:00-${(hour + 1).toString().padLeft(2, '0')}:00';

    showDialog(
      context: context,
      builder: (context) => _AppointmentCreateDialog(
        therapistId: therapistId,
        therapistName: therapistName,
        selectedDate: _selectedDate,
        timeSlot: timeSlot,
        patients: _patients,
        onCreated: () {
          Navigator.pop(context);
          _loadAppointments();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 관리'),
        actions: [
          // 뷰 모드 선택 드롭다운
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _viewMode,
              underline: const SizedBox(),
              dropdownColor: Colors.white,
              items: ['일', '주', '월'].map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _viewMode = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // 좌측: 미니 캘린더
          Container(
            width: 350,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: _buildMiniCalendar(),
          ),

          // 우측: 치료사별 시간표
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildScheduleTable(),
          ),
        ],
      ),
    );
  }

  /// 미니 캘린더 위젯
  Widget _buildMiniCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDate,
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      onDaySelected: _onDateSelected,
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blue.shade200,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 시간표 위젯
  Widget _buildScheduleTable() {
    if (_therapists.isEmpty) {
      return const Center(child: Text('등록된 치료사가 없습니다'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 날짜 헤더
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _getWeekdayText(_selectedDate.weekday),
                  style: TextStyle(
                    fontSize: 18,
                    color: _selectedDate.weekday == 7 ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // 시간표
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTimeTable(),
          ),
        ],
      ),
    );
  }

  /// 시간표 테이블
  Widget _buildTimeTable() {
    final hours = List.generate(10, (index) => 9 + index); // 09:00 ~ 18:00

    return DataTable(
      columnSpacing: 0,
      headingRowHeight: 60,
      dataRowHeight: 80,
      columns: [
        // 시간 열
        const DataColumn(
          label: SizedBox(
            width: 80,
            child: Center(child: Text('시간', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        ),
        // 치료사 열
        ..._therapists.map((therapist) {
          return DataColumn(
            label: SizedBox(
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    therapist['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSpecialtyText(therapist['specialty']!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
      rows: hours.map((hour) {
        return DataRow(
          cells: [
            // 시간 셀
            DataCell(
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            // 치료사별 예약 셀
            ..._therapists.map((therapist) {
              final therapistId = therapist['id']!;
              final appointments = _appointmentsByTherapist[therapistId] ?? [];

              // 해당 시간대의 예약 찾기
              final timeSlot = '${hour.toString().padLeft(2, '0')}:00-${(hour + 1).toString().padLeft(2, '0')}:00';
              final appointment = appointments.firstWhere(
                (apt) => apt.timeSlot == timeSlot,
                orElse: () => Appointment(
                  id: '',
                  patientId: '',
                  patientName: '',
                  guardianId: '',
                  therapistId: '',
                  therapistName: '',
                  appointmentDate: DateTime.now(),
                  timeSlot: '',
                  status: AppointmentStatus.pending,
                  createdAt: DateTime.now(),
                ),
              );

              return DataCell(
                InkWell(
                  onTap: () => _onTimeSlotTapped(therapistId, therapist['name']!, hour),
                  child: Container(
                    width: 200,
                    height: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appointment.id.isNotEmpty
                          ? _getStatusColor(appointment.status)
                          : Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: appointment.id.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                appointment.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStatusText(appointment.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Icon(Icons.add, color: Colors.grey),
                          ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  /// 요일 텍스트
  String _getWeekdayText(int weekday) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return weekdays[weekday - 1];
  }

  /// 전문 분야 텍스트
  String _getSpecialtyText(String specialty) {
    switch (specialty) {
      case 'physical_therapy':
        return '물리치료';
      case 'occupational_therapy':
        return '작업치료';
      case 'speech_therapy':
        return '언어치료';
      default:
        return '일반';
    }
  }

  /// 상태별 색상
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.blue.shade100;
      case AppointmentStatus.pending:
        return Colors.orange.shade100;
      case AppointmentStatus.cancelled:
        return Colors.red.shade100;
      case AppointmentStatus.completed:
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  /// 상태 텍스트
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
      default:
        return '';
    }
  }
}

/// 예약 생성 다이얼로그
class _AppointmentCreateDialog extends StatefulWidget {
  final String therapistId;
  final String therapistName;
  final DateTime selectedDate;
  final String timeSlot;
  final List<Patient> patients;
  final VoidCallback onCreated;

  const _AppointmentCreateDialog({
    required this.therapistId,
    required this.therapistName,
    required this.selectedDate,
    required this.timeSlot,
    required this.patients,
    required this.onCreated,
  });

  @override
  State<_AppointmentCreateDialog> createState() => _AppointmentCreateDialogState();
}

class _AppointmentCreateDialogState extends State<_AppointmentCreateDialog> {
  Patient? _selectedPatient;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('예약 생성'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 치료사 정보
            _buildInfoRow('치료사', widget.therapistName),
            const SizedBox(height: 8),
            // 날짜
            _buildInfoRow('날짜', '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}'),
            const SizedBox(height: 8),
            // 시간
            _buildInfoRow('시간', widget.timeSlot),
            const Divider(height: 32),

            // 환자 선택
            const Text(
              '환자 선택',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // 환자 목록
            SizedBox(
              height: 300,
              child: widget.patients.isEmpty
                  ? const Center(child: Text('등록된 환자가 없습니다'))
                  : ListView.builder(
                      itemCount: widget.patients.length,
                      itemBuilder: (context, index) {
                        final patient = widget.patients[index];
                        return RadioListTile<Patient>(
                          title: Text(patient.name),
                          subtitle: Text('${patient.patientCode} | ${_getGenderText(patient.gender)}'),
                          value: patient,
                          groupValue: _selectedPatient,
                          onChanged: (value) {
                            setState(() {
                              _selectedPatient = value;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _selectedPatient == null || _isCreating ? null : _createAppointment,
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('예약 생성'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'M':
        return '남';
      case 'F':
        return '여';
      default:
        return '기타';
    }
  }

  Future<void> _createAppointment() async {
    if (_selectedPatient == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final appointmentTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        int.parse(widget.timeSlot.split(':')[0]),
      );

      final appointment = Appointment(
        id: 'new_appointment_${DateTime.now().millisecondsSinceEpoch}',
        patientId: _selectedPatient!.id,
        patientName: _selectedPatient!.name,
        guardianId: _selectedPatient!.guardianIds.isNotEmpty ? _selectedPatient!.guardianIds.first : '',
        therapistId: widget.therapistId,
        therapistName: widget.therapistName,
        appointmentDate: appointmentTime,
        timeSlot: widget.timeSlot,
        status: AppointmentStatus.confirmed,
        createdAt: DateTime.now(),
      );

      final appointmentService = AppointmentService();
      await appointmentService.createAppointment(appointment);

      print('✅ 예약 생성 완료: ${_selectedPatient!.name} - ${widget.timeSlot}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약이 생성되었습니다')),
      );

      widget.onCreated();
    } catch (e) {
      print('❌ 예약 생성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약 생성 실패: $e')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
}
