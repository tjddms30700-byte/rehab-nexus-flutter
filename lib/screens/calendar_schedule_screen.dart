import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../constants/enums.dart';
import '../services/appointment_service.dart';
import '../services/patient_service.dart';
import '../widgets/create_appointment_dialog.dart'; // 새 다이얼로그 import

/// 새로운 일정관리 화면 - 캘린더 + 치료사별 시간표
class CalendarScheduleScreen extends StatefulWidget {
  const CalendarScheduleScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScheduleScreen> createState() => _CalendarScheduleScreenState();
}

class _CalendarScheduleScreenState extends State<CalendarScheduleScreen> {
  final AppointmentService _appointmentService = AppointmentService();

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

  // 공휴일 목록
  List<DateTime> _holidays = [];
  
  // 휴무일 목록 (정기 휴무)
  Map<String, bool> _regularOffDays = {};

  // 로딩 상태
  bool _isLoading = true;

  // 우측 패널 상태
  bool _isRightPanelOpen = false;
  Appointment? _selectedAppointment;
  String? _selectedTherapistId;
  String? _selectedTherapistName;
  int? _selectedHour;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
    _loadTherapists();
  }

  /// 공휴일 로드
  Future<void> _loadHolidays() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('work_hours_settings')
          .doc('main')
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.data()!;
        
        // 정기 휴무일 (요일별)
        _regularOffDays = {
          'monday': data['monday_work'] == false,
          'tuesday': data['tuesday_work'] == false,
          'wednesday': data['wednesday_work'] == false,
          'thursday': data['thursday_work'] == false,
          'friday': data['friday_work'] == false,
          'saturday': data['saturday_work'] == false,
          'sunday': data['sunday_work'] == false,
        };
        
        // 공휴일 목록
        final holidays = data['holidays'] as List<dynamic>? ?? [];
        _holidays = holidays.map((holiday) {
          if (holiday is Map && holiday['date'] is Timestamp) {
            return (holiday['date'] as Timestamp).toDate();
          }
          return null;
        }).whereType<DateTime>().toList();
      }
    } catch (e) {
      print('❌ 공휴일 로드 실패: $e');
    }
  }

  /// 해당 날짜가 휴무일인지 확인
  bool _isOffDay(DateTime date) {
    // 공휴일 체크
    for (var holiday in _holidays) {
      if (holiday.year == date.year &&
          holiday.month == date.month &&
          holiday.day == date.day) {
        return true;
      }
    }
    
    // 정기 휴무일 체크
    final weekdayKey = _getWeekdayKey(date.weekday);
    return _regularOffDays[weekdayKey] == true;
  }
  
  String _getWeekdayKey(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'sunday';
    }
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

  /// 시간 슬롯 클릭 시 - 우측 패널 열기
  void _onTimeSlotTapped(String therapistId, String therapistName, int hour, Appointment? appointment) {
    setState(() {
      _isRightPanelOpen = true;
      _selectedAppointment = appointment;
      _selectedTherapistId = therapistId;
      _selectedTherapistName = therapistName;
      _selectedHour = hour;
    });
  }

  /// 우측 패널 닫기
  void _closeRightPanel() {
    setState(() {
      _isRightPanelOpen = false;
      _selectedAppointment = null;
      _selectedTherapistId = null;
      _selectedTherapistName = null;
      _selectedHour = null;
    });
  }

  /// 예약 생성 다이얼로그 열기
  Future<void> _showCreateAppointmentDialog() async {
    if (_selectedTherapistId == null || _selectedTherapistName == null || _selectedHour == null) {
      return;
    }

    // 휴무일 체크
    if (_isOffDay(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('휴무일에는 예약을 생성할 수 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final timeSlot = '${_selectedHour!.toString().padLeft(2, '0')}:00-${(_selectedHour! + 1).toString().padLeft(2, '0')}:00';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateAppointmentDialog(
        therapistId: _selectedTherapistId!,
        therapistName: _selectedTherapistName!,
        selectedDate: _selectedDate,
        initialTimeSlot: timeSlot,
        patients: _patients,
      ),
    );

    // 예약 생성 성공 시 데이터 새로고침
    if (result == true) {
      _loadAppointments();
      _closeRightPanel();
    }
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

          // 중앙: 일/주/월에 따라 다른 화면
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildViewByMode(),
          ),

          // 우측: 작업 패널 (슬라이드 방식)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isRightPanelOpen ? 400 : 0,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
              color: Colors.white,
            ),
            child: _isRightPanelOpen ? _buildRightPanel() : null,
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
        // 휴무일 스타일
        disabledDecoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        disabledTextStyle: const TextStyle(
          color: Colors.grey,
          decoration: TextDecoration.lineThrough,
        ),
      ),
      // 휴무일 활성화 여부 결정
      enabledDayPredicate: (day) {
        return !_isOffDay(day);
      },
      // 휴무일 스타일 빌더
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          if (_isOffDay(day)) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  /// 뷰 모드에 따른 화면 분기
  Widget _buildViewByMode() {
    switch (_viewMode) {
      case '일':
        return _buildDailyView();
      case '주':
        return _buildWeeklyView();
      case '월':
        return _buildMonthlyView();
      default:
        return _buildDailyView();
    }
  }

  /// 일간 보기 (치료사별 시간표)
  Widget _buildDailyView() {
    if (_therapists.isEmpty) {
      return const Center(child: Text('등록된 치료사가 없습니다'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 날짜 헤더
          Container(
            padding: const EdgeInsets.all(16),
            color: _isOffDay(_selectedDate) ? Colors.grey.shade300 : Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isOffDay(_selectedDate) ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _getWeekdayText(_selectedDate.weekday),
                  style: TextStyle(
                    fontSize: 18,
                    color: _isOffDay(_selectedDate) 
                        ? Colors.grey 
                        : (_selectedDate.weekday == 7 ? Colors.red : Colors.grey.shade700),
                  ),
                ),
                if (_isOffDay(_selectedDate)) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '휴무일',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
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
                  onTap: () => _onTimeSlotTapped(
                    therapistId, 
                    therapist['name']!, 
                    hour,
                    appointment.id.isNotEmpty ? appointment : null,
                  ),
                  child: Container(
                    width: 200,
                    height: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appointment.id.isNotEmpty
                          ? appointment.slotColor
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
                                appointment.slotStatusText,
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

  /// 주간 보기 (7일 가로 레이아웃)
  Widget _buildWeeklyView() {
    // 선택된 주의 시작일(월요일)과 종료일(일요일) 계산
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return SingleChildScrollView(
      child: Column(
        children: [
          // 주간 헤더
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                      _focusedDate = _selectedDate;
                      _isLoading = true;
                    });
                    _loadAppointments();
                  },
                ),
                Text(
                  '${weekDays.first.year}년 ${weekDays.first.month}월 ${weekDays.first.day}일 ~ ${weekDays.last.month}월 ${weekDays.last.day}일',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                      _focusedDate = _selectedDate;
                      _isLoading = true;
                    });
                    _loadAppointments();
                  },
                ),
              ],
            ),
          ),

          // 주간 시간표 (간단한 버전)
          DataTable(
            columns: [
              const DataColumn(label: Text('시간')),
              ...weekDays.map((date) => DataColumn(
                label: Text(
                  '${date.month}/${date.day}\n${_getWeekdayText(date.weekday).substring(0, 1)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: date.day == DateTime.now().day ? Colors.blue : Colors.black,
                    fontWeight: date.day == DateTime.now().day ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )),
            ],
            rows: List.generate(10, (index) {
              final hour = 9 + index;
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      width: 80,
                      alignment: Alignment.center,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    ),
                  ),
                  ...weekDays.map((date) {
                    // 해당 날짜/시간의 예약 개수 표시
                    return DataCell(
                      Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey.shade50,
                        child: const Center(
                          child: Text('-', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 월간 보기 (캘린더 + 예약 개수)
  Widget _buildMonthlyView() {
    return Column(
      children: [
        // 월간 헤더
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                    _focusedDate = _selectedDate;
                  });
                },
              ),
              Text(
                '${_selectedDate.year}년 ${_selectedDate.month}월',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                    _focusedDate = _selectedDate;
                  });
                },
              ),
            ],
          ),
        ),

        // 큰 캘린더 (table_calendar 활용)
        Expanded(
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDate, focusedDate) {
              setState(() {
                _selectedDate = selectedDate;
                _focusedDate = focusedDate;
                _viewMode = '일'; // 날짜 클릭 시 일간 보기로 전환
                _isLoading = true;
              });
              _loadAppointments();
            },
            calendarFormat: CalendarFormat.month,
            headerVisible: false, // 헤더는 위에서 이미 만들었으므로 숨김
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              // 예약 개수 표시 (간단한 마커)
              markerBuilder: (context, date, events) {
                // TODO: 실제 예약 데이터 기반으로 마커 표시
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 우측 작업 패널
  Widget _buildRightPanel() {
    return Container(
      width: 400,
      color: Colors.white,
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '수업 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeRightPanel,
                ),
              ],
            ),
          ),

          // 패널 내용
          Expanded(
            child: _selectedAppointment != null
                ? _buildAppointmentDetails()
                : _buildEmptySlot(),
          ),
        ],
      ),
    );
  }

  /// 예약 상세 정보
  Widget _buildAppointmentDetails() {
    final apt = _selectedAppointment!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 슬롯 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: apt.slotColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              apt.slotStatusText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 환자 정보
          _buildInfoSection(
            title: '환자 정보',
            items: [
              _buildInfoRow(Icons.person, '이름', apt.patientName),
              _buildInfoRow(Icons.access_time, '시간', apt.timeSlot),
              _buildInfoRow(Icons.person_outline, '담당', apt.therapistName),
            ],
          ),
          const SizedBox(height: 16),

          // 출석 정보
          if (apt.attended || apt.attendedAt != null) ...[
            _buildInfoSection(
              title: '출석 정보',
              items: [
                _buildInfoRow(
                  Icons.check_circle,
                  '출석 여부',
                  apt.attended ? '출석 완료' : '미출석',
                ),
                if (apt.attendedAt != null)
                  _buildInfoRow(
                    Icons.calendar_today,
                    '출석 시각',
                    '${apt.attendedAt!.month}/${apt.attendedAt!.day} ${apt.attendedAt!.hour}:${apt.attendedAt!.minute.toString().padLeft(2, '0')}',
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 세션 정보
          if (apt.sessionRecorded || apt.sessionRecordedAt != null) ...[
            _buildInfoSection(
              title: '세션 기록',
              items: [
                _buildInfoRow(
                  Icons.description,
                  '기록 여부',
                  apt.sessionRecorded ? '기록 완료' : '미기록',
                ),
                if (apt.sessionRecordedAt != null)
                  _buildInfoRow(
                    Icons.calendar_today,
                    '기록 시각',
                    '${apt.sessionRecordedAt!.month}/${apt.sessionRecordedAt!.day} ${apt.sessionRecordedAt!.hour}:${apt.sessionRecordedAt!.minute.toString().padLeft(2, '0')}',
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 보강 정보
          if (apt.isMakeup && apt.makeupTicketId != null) ...[
            _buildInfoSection(
              title: '보강 정보',
              items: [
                _buildInfoRow(Icons.replay, '보강 수업', '보강권 사용'),
                _buildInfoRow(Icons.confirmation_number, '보강권 ID', apt.makeupTicketId!),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 메모
          if (apt.notes != null && apt.notes!.isNotEmpty) ...[
            _buildInfoSection(
              title: '메모',
              items: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(apt.notes!),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // 액션 버튼들
          _buildActionButtons(apt),
        ],
      ),
    );
  }

  /// 빈 슬롯 정보
  Widget _buildEmptySlot() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 슬롯 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '빈 슬롯',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 슬롯 정보
          _buildInfoSection(
            title: '슬롯 정보',
            items: [
              _buildInfoRow(Icons.person_outline, '담당', _selectedTherapistName ?? ''),
              _buildInfoRow(
                Icons.access_time,
                '시간',
                '${_selectedHour!.toString().padLeft(2, '0')}:00-${(_selectedHour! + 1).toString().padLeft(2, '0')}:00',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                '날짜',
                '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 예약 생성 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showCreateAppointmentDialog,
              icon: const Icon(Icons.add),
              label: const Text(
                '예약 생성',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 정보 섹션 빌더
  Widget _buildInfoSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  /// 정보 행 빌더
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼들
  Widget _buildActionButtons(Appointment apt) {
    return Column(
      children: [
        // 출석 처리
        if (!apt.attended) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _markAttendance(apt),
              icon: const Icon(Icons.check_circle),
              label: const Text('출석 처리'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 세션 기록
        if (apt.attended && !apt.sessionRecorded) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _goToSessionRecord(apt),
              icon: const Icon(Icons.description),
              label: const Text('세션 기록'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 예약 취소
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _cancelAppointment(apt),
            icon: const Icon(Icons.cancel),
            label: const Text('예약 취소'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  /// 출석 처리
  Future<void> _markAttendance(Appointment apt) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(apt.id)
          .update({
        'attended': true,
        'attended_at': FieldValue.serverTimestamp(),
        'status': 'CONFIRMED',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출석 처리되었습니다')),
      );

      _loadAppointments();
      _closeRightPanel();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출석 처리 실패: $e')),
      );
    }
  }

  /// 세션 기록 화면으로 이동
  void _goToSessionRecord(Appointment apt) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('세션 기록 화면으로 이동합니다 (구현 예정)')),
    );
    // TODO: Navigator.push to session record screen
  }

  /// 예약 취소
  Future<void> _cancelAppointment(Appointment apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('정말 이 예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(apt.id)
            .update({
          'status': 'CANCELLED',
          'updated_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('예약이 취소되었습니다')),
        );

        _loadAppointments();
        _closeRightPanel();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('예약 취소 실패: $e')),
        );
      }
    }
  }
}

/// 예약 생성 다이얼로그
