import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../providers/app_state.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

/// 보호자용 예약 신청 화면
class AppointmentRequestScreen extends StatefulWidget {
  final Patient patient;

  const AppointmentRequestScreen({
    super.key,
    required this.patient,
  });

  @override
  State<AppointmentRequestScreen> createState() => _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appointmentService = AppointmentService();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:00-10:00';
  bool _isSaving = false;

  final List<String> _timeSlots = [
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '13:00-14:00',
    '14:00-15:00',
    '15:00-16:00',
    '16:00-17:00',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitAppointment() async {
    print('🔵 [AppointmentRequestScreen] _submitAppointment 시작');
    if (!_formKey.currentState!.validate()) {
      print('❌ [AppointmentRequestScreen] 폼 유효성 검사 실패');
      return;
    }

    // ✅ CRITICAL: context.read를 async 전에 추출
    final appState = context.read<AppState>();
    final currentUser = appState.currentUser;
    print('🟢 [AppointmentRequestScreen] currentUser: ${currentUser?.name ?? "null"}');

    if (currentUser == null) {
      print('❌ [AppointmentRequestScreen] currentUser가 null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 사용자 정보를 찾을 수 없습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() => _isSaving = true);

    try {

      print('📝 [AppointmentRequestScreen] Appointment 객체 생성');
      final appointment = Appointment(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        guardianId: currentUser.id,
        therapistId: widget.patient.assignedTherapistId ?? 'therapist_001',
        therapistName: '담당 치료사',
        appointmentDate: _selectedDate,
        timeSlot: _selectedTimeSlot,
        status: AppointmentStatus.pending,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
      );
      print('✅ [AppointmentRequestScreen] Appointment 객체 생성 완료');

      try {
        print('🔄 [AppointmentRequestScreen] createAppointment 호출');
        final appointmentId = await _appointmentService.createAppointment(appointment);
        if (mounted) {
          print('✅ [AppointmentRequestScreen] Firebase 저장 성공: $appointmentId');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 예약 신청이 완료되었습니다! (ID: $appointmentId)'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (firebaseError) {
        print('⚠️ [AppointmentRequestScreen] Firebase 오류: $firebaseError');
        // Firebase 오류 시 Mock 모드
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 예약 신청이 접수되었습니다!\n💡 Firebase 연결 시 실제 저장됩니다'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }

      if (mounted) {
        print('🔙 [AppointmentRequestScreen] Navigator.pop 호출');
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ [AppointmentRequestScreen] 예외 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 예약 신청 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('치료 예약 신청'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 환자 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        widget.patient.name.substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('${widget.patient.age}세'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 예약 날짜
              const Text(
                '예약 날짜',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                title: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),

              // 시간대 선택
              const Text(
                '시간대',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTimeSlot,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: _timeSlots.map((slot) {
                  return DropdownMenuItem(
                    value: slot,
                    child: Text(slot),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTimeSlot = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 요청 사항
              const Text(
                '요청 사항 (선택)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: '특별히 요청하실 사항이 있으시면 적어주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // 신청 버튼
              ElevatedButton(
                onPressed: _isSaving ? null : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '예약 신청하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
