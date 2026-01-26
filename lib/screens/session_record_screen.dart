import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../constants/app_theme.dart';

/// 세션 기록 화면 - 초간단 버전 (테스트용)
class SessionRecordScreen extends StatefulWidget {
  final Patient patient;

  const SessionRecordScreen({
    super.key,
    required this.patient,
  });

  @override
  State<SessionRecordScreen> createState() => _SessionRecordScreenState();
}

class _SessionRecordScreenState extends State<SessionRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _sessionDate = DateTime.now();
  int _sessionNumber = 1;
  
  final _activity1Controller = TextEditingController();
  String _mood = '좋음';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _activity1Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _sessionDate) {
      setState(() {
        _sessionDate = picked;
      });
    }
  }

  void _saveSession() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 세션 정보가 입력되었습니다!\n💡 Firebase 연결 시 실제 저장됩니다'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.name} - 세션 기록'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 환자 정보 (단순화)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
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

              // 세션 날짜
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('세션 날짜'),
                subtitle: Text(
                  '${_sessionDate.year}-${_sessionDate.month.toString().padLeft(2, '0')}-${_sessionDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // 세션 번호
              TextFormField(
                initialValue: _sessionNumber.toString(),
                decoration: const InputDecoration(
                  labelText: '세션 번호',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '세션 번호를 입력하세요';
                  }
                  return null;
                },
                onChanged: (value) {
                  _sessionNumber = int.tryParse(value) ?? 1;
                },
              ),
              const SizedBox(height: 16),

              // 활동 내용
              TextFormField(
                controller: _activity1Controller,
                decoration: const InputDecoration(
                  labelText: '활동 내용',
                  hintText: '예: 수중 걷기, 균형 운동 등',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '활동 내용을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 환자 기분
              DropdownButtonFormField<String>(
                value: _mood,
                decoration: const InputDecoration(
                  labelText: '환자 기분',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '좋음', child: Text('😊 좋음')),
                  DropdownMenuItem(value: '보통', child: Text('😐 보통')),
                  DropdownMenuItem(value: '나쁨', child: Text('😢 나쁨')),
                ],
                onChanged: (value) {
                  setState(() {
                    _mood = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 관찰 내용
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '관찰 내용',
                  hintText: '환자의 반응, 특이사항 등을 기록해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              ElevatedButton(
                onPressed: _saveSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '세션 저장',
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
