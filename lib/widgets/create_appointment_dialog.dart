import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../constants/enums.dart'; // AppointmentStatus import 추가

/// 예약 생성 다이얼로그 (탭 구조)
class CreateAppointmentDialog extends StatefulWidget {
  final String therapistId;
  final String therapistName;
  final DateTime selectedDate;
  final String? initialTimeSlot;
  final List<Patient> patients;

  const CreateAppointmentDialog({
    Key? key,
    required this.therapistId,
    required this.therapistName,
    required this.selectedDate,
    this.initialTimeSlot,
    required this.patients,
  }) : super(key: key);

  @override
  State<CreateAppointmentDialog> createState() => _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 예약 기본 정보
  Patient? _selectedPatient;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _classType = 'STANDARD'; // STANDARD, SPECIAL, MAKEUP
  int _sessionCount = 10;
  
  // 예약금
  int _depositAmount = 0;
  
  // 메모
  final TextEditingController _memoController = TextEditingController();
  
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // 초기 시간 설정 (전달받은 timeSlot 파싱)
    if (widget.initialTimeSlot != null) {
      _parseInitialTimeSlot(widget.initialTimeSlot!);
    }
  }

  void _parseInitialTimeSlot(String timeSlot) {
    // "10:00-11:00" 형식 파싱
    final parts = timeSlot.split('-');
    if (parts.length == 2) {
      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // 상단 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_note, color: Colors.pink),
                  const SizedBox(width: 8),
                  const Text(
                    '등록하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // 탭 바
            TabBar(
              controller: _tabController,
              labelColor: Colors.pink,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.pink,
              tabs: const [
                Tab(text: '예약등록'),
                Tab(text: '수업하기'),
                Tab(text: '설문'),
                Tab(text: '수납(권)'),
              ],
            ),
            
            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReservationTab(),
                  _buildClassTab(),
                  _buildSurveyTab(),
                  _buildPaymentTab(),
                ],
              ),
            ),
            
            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('발송하기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('예약등록'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 예약등록 탭
  Widget _buildReservationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 고객 선택
          _buildSectionTitle('고객'),
          const SizedBox(height: 8),
          _buildPatientSelector(),
          const SizedBox(height: 24),
          
          // 수업일시
          _buildSectionTitle('수업일시'),
          const SizedBox(height: 8),
          _buildDateTimeSelector(),
          const SizedBox(height: 24),
          
          // 수업
          _buildSectionTitle('수업'),
          const SizedBox(height: 8),
          _buildClassTypeSelector(),
          const SizedBox(height: 24),
          
          // 예약금
          _buildSectionTitle('예약금'),
          const SizedBox(height: 8),
          _buildDepositInput(),
          const SizedBox(height: 24),
          
          // 예약메모
          _buildSectionTitle('예약메모'),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '예약 메모를 입력하세요',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  /// 수업하기 탭
  Widget _buildClassTab() {
    return const Center(
      child: Text('수업 관리 기능 (추후 구현)'),
    );
  }

  /// 설문 탭
  Widget _buildSurveyTab() {
    return const Center(
      child: Text('설문 기능 (추후 구현)'),
    );
  }

  /// 수납(권) 탭
  Widget _buildPaymentTab() {
    return const Center(
      child: Text('수납/바우처 관리 (추후 구현)'),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 환자 선택기
  Widget _buildPatientSelector() {
    return InkWell(
      onTap: _showPatientSelectionDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text(
              _selectedPatient != null
                  ? '${_selectedPatient!.name} (${_selectedPatient!.patientCode})'
                  : '고객을 선택하세요',
              style: TextStyle(
                color: _selectedPatient != null ? Colors.black : Colors.grey,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 환자 선택 다이얼로그
  void _showPatientSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 선택'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: widget.patients.isEmpty
              ? const Center(child: Text('등록된 환자가 없습니다'))
              : ListView.builder(
                  itemCount: widget.patients.length,
                  itemBuilder: (context, index) {
                    final patient = widget.patients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink.shade100,
                        child: Text(patient.name[0]),
                      ),
                      title: Text(patient.name),
                      subtitle: Text('${patient.patientCode} | ${_getGenderText(patient.gender)}'),
                      onTap: () {
                        setState(() {
                          _selectedPatient = patient;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
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

  /// 날짜/시간 선택기
  Widget _buildDateTimeSelector() {
    return Column(
      children: [
        // 날짜
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')} (${_getWeekdayText(widget.selectedDate.weekday)})',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 시간
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showTimeSelectionDialog(isStartTime: true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _startTime != null
                            ? '오후 ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                            : '시작 시간',
                        style: TextStyle(
                          color: _startTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _showTimeSelectionDialog(isStartTime: false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _endTime != null
                            ? '오후 ${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                            : '종료 시간',
                        style: TextStyle(
                          color: _endTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '1시간 10분',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 시간 선택 다이얼로그 (10분 단위 그리드)
  void _showTimeSelectionDialog({required bool isStartTime}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(
                      '하유정 예약시간',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // 날짜 정보
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '예약날짜',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')} (${_getWeekdayText(widget.selectedDate.weekday)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '소요시간',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1시간 10분',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '예약시간',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _startTime != null && _endTime != null
                          ? '(오후 ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')} ~ 오후 ${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')})'
                          : '시간을 선택하세요',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // 시간 그리드 (오전/오후)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 오전
                      _buildTimeSection('오전', 10, 12),
                      const SizedBox(height: 24),
                      
                      // 오후
                      _buildTimeSection('오후', 12, 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 시간 섹션 (오전/오후)
  Widget _buildTimeSection(String label, int startHour, int endHour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            (endHour - startHour) * 6, // 10분 단위
            (index) {
              final hour = startHour + (index ~/ 6);
              final minute = (index % 6) * 10;
              final time = TimeOfDay(hour: hour, minute: minute);
              final isSelected = (_startTime?.hour == hour && _startTime?.minute == minute);
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _startTime = time;
                    _endTime = TimeOfDay(
                      hour: hour + 1,
                      minute: minute + 10,
                    );
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade100 : Colors.grey.shade100,
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 수업 종류 선택
  Widget _buildClassTypeSelector() {
    return Column(
      children: [
        // 수업 추가 버튼
        InkWell(
          onTap: () {
            // TODO: 수업 추가 로직
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Text('수업 추가'),
                const Spacer(),
                const Icon(Icons.add, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 바우처 추가 버튼
        InkWell(
          onTap: () {
            // TODO: 바우처 추가 로직
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Text('바우처 추가'),
                const Spacer(),
                const Icon(Icons.add, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 선택된 수업 표시 (STANDARD / 1시간 10분)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'STANDARD',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              const Text('1시간 10분'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  // TODO: 수업 삭제
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 예약금 입력
  Widget _buildDepositInput() {
    return Row(
      children: [
        // 하트 아이콘
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.favorite, color: Colors.pink, size: 20),
        ),
        const SizedBox(width: 12),
        
        // 금액 입력
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '35,000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              _depositAmount = int.tryParse(value.replaceAll(',', '')) ?? 0;
            },
          ),
        ),
      ],
    );
  }

  String _getWeekdayText(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
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

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      // TODO: 날짜 변경 로직
    }
  }

  Future<void> _createAppointment() async {
    if (_selectedPatient == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 정보를 모두 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final appointmentTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      await FirebaseFirestore.instance.collection('appointments').add({
        'patient_id': _selectedPatient!.id,
        'patient_name': _selectedPatient!.name,
        'therapist_id': widget.therapistId,
        'therapist_name': widget.therapistName,
        'appointment_time': Timestamp.fromDate(appointmentTime),
        'end_time': Timestamp.fromDate(endTime),
        'status': 'CONFIRMED', // enum을 문자열로 직접 변환
        'session_type': _classType,
        'session_count': _sessionCount,
        'deposit_amount': _depositAmount,
        'notes': _memoController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 예약이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('예약 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
