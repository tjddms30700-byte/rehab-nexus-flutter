import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 업무시간 및 휴무 설정 화면
class WorkHoursSettingsScreen extends StatefulWidget {
  const WorkHoursSettingsScreen({Key? key}) : super(key: key);

  @override
  State<WorkHoursSettingsScreen> createState() => _WorkHoursSettingsScreenState();
}

class _WorkHoursSettingsScreenState extends State<WorkHoursSettingsScreen> {
  // 요일별 업무 설정
  final Map<String, Map<String, dynamic>> _weekdaySettings = {
    '일': {'isWorking': false, 'startTime': '09:00', 'endTime': '18:00'},
    '월': {'isWorking': true, 'startTime': '09:00', 'endTime': '18:00'},
    '화': {'isWorking': true, 'startTime': '09:00', 'endTime': '18:00'},
    '수': {'isWorking': true, 'startTime': '09:00', 'endTime': '18:00'},
    '목': {'isWorking': true, 'startTime': '09:00', 'endTime': '18:00'},
    '금': {'isWorking': true, 'startTime': '09:00', 'endTime': '18:00'},
    '토': {'isWorking': false, 'startTime': '09:00', 'endTime': '18:00'},
  };

  // 정기 휴무
  final List<String> _regularHolidays = ['매주 일요일'];

  // 공휴일
  final List<Map<String, dynamic>> _holidays = [
    {'name': '설날', 'date': '2026-01-29'},
    {'name': '추석', 'date': '2026-09-27'},
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Firebase에서 설정 불러오기
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('settings').doc('work_hours').set({
        'weekday_settings': _weekdaySettings,
        'regular_holidays': _regularHolidays,
        'holidays': _holidays,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 설정이 저장되었습니다'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 업무시간 설정
                  _buildSectionTitle('1. 업무시간 설정'),
                  const SizedBox(height: 16),
                  _buildWorkHoursTable(),
                  const SizedBox(height: 32),

                  // 2. 휴무 설정
                  _buildSectionTitle('2. 휴무 설정'),
                  const SizedBox(height: 16),
                  _buildRegularHolidaysSection(),
                  const SizedBox(height: 24),
                  _buildHolidaysSection(),
                  const SizedBox(height: 32),

                  // 저장 버튼
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('설정 저장'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 업무시간 테이블
  Widget _buildWorkHoursTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 80, child: Text('요일', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 100, child: Text('근무 상태', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('업무 시간', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // 요일별 설정
          ..._weekdaySettings.entries.map((entry) {
            final weekday = entry.key;
            final settings = entry.value;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  // 요일
                  SizedBox(
                    width: 80,
                    child: Text(
                      weekday,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // 근무/휴무 선택
                  SizedBox(
                    width: 100,
                    child: Switch(
                      value: settings['isWorking'] as bool,
                      onChanged: (value) {
                        setState(() {
                          settings['isWorking'] = value;
                        });
                      },
                    ),
                  ),
                  // 시간 선택
                  Expanded(
                    child: (settings['isWorking'] as bool)
                        ? Row(
                            children: [
                              // 시작 시간
                              InkWell(
                                onTap: () => _selectTime(weekday, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(settings['startTime'] as String),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('~'),
                              ),
                              // 종료 시간
                              InkWell(
                                onTap: () => _selectTime(weekday, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(settings['endTime'] as String),
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            '휴무',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 정기 휴무 섹션
  Widget _buildRegularHolidaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '정기 휴무',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ..._regularHolidays.map((holiday) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(holiday, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _regularHolidays.remove(holiday);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addRegularHoliday,
                icon: const Icon(Icons.add),
                label: const Text('정기 휴무 추가'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 공휴일 섹션
  Widget _buildHolidaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공휴일',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ..._holidays.map((holiday) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        '${holiday['name']} (${holiday['date']})',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _holidays.remove(holiday);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addHoliday,
                icon: const Icon(Icons.add),
                label: const Text('공휴일 추가'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 시간 선택
  Future<void> _selectTime(String weekday, bool isStartTime) async {
    final currentTime = _weekdaySettings[weekday]![isStartTime ? 'startTime' : 'endTime'] as String;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _weekdaySettings[weekday]![isStartTime ? 'startTime' : 'endTime'] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  /// 정기 휴무 추가
  void _addRegularHoliday() {
    showDialog(
      context: context,
      builder: (context) {
        String holidayText = '';
        return AlertDialog(
          title: const Text('정기 휴무 추가'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: '예) 매주 일요일',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              holidayText = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (holidayText.isNotEmpty) {
                  setState(() {
                    _regularHolidays.add(holidayText);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  /// 공휴일 추가
  void _addHoliday() {
    showDialog(
      context: context,
      builder: (context) {
        String holidayName = '';
        DateTime selectedDate = DateTime.now();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('공휴일 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '공휴일 이름',
                      hintText: '예) 설날',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      holidayName = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('날짜: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (holidayName.isNotEmpty) {
                      this.setState(() {
                        _holidays.add({
                          'name': holidayName,
                          'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
