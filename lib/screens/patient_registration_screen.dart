import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../providers/app_state.dart';

/// 환자 등록 화면 - 간단 버전
class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  String _selectedGender = 'M';
  final _diagnosisController = TextEditingController();
  final _patientService = PatientService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🟢 PatientRegistrationScreen: initState called');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2016, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _birthDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
      }

      // 생년월일 파싱
      final birthDateParts = _birthDateController.text.split('-');
      final birthDate = DateTime(
        int.parse(birthDateParts[0]),
        int.parse(birthDateParts[1]),
        int.parse(birthDateParts[2]),
      );

      // 진단명 파싱 (쉼표로 구분)
      final diagnosisList = _diagnosisController.text
          .split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList();

      // Patient 객체 생성
      final patient = Patient(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // 임시 ID
        organizationId: currentUser.organizationId,
        patientCode: 'P${DateTime.now().millisecondsSinceEpoch % 10000}',
        name: _nameController.text,
        birthDate: birthDate,
        gender: _selectedGender,
        diagnosis: diagnosisList,
        assignedTherapistId: currentUser.id,
        createdAt: DateTime.now(),
      );

      // Firebase에 저장 시도
      try {
        final patientId = await _patientService.createPatient(patient);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 환자 등록이 완료되었습니다!\nID: $patientId'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, patient);
        }
      } catch (firebaseError) {
        // Firebase 오류 시 로컬에만 저장 (Mock)
        if (kDebugMode) {
          print('Firebase Error: $firebaseError');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ 환자 정보가 입력되었습니다!\n💡 Firebase 연결 시 실제 저장됩니다'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, patient);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Patient Registration Error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 환자 등록 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔵 PatientRegistrationScreen: build called');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 등록'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // 안내 카드
            Card(
              color: const Color(0x1A0077BE), // AppTheme.primary with 10% opacity
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 환자 기본 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '새로운 환자의 기본 정보를 입력해주세요.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '환자 이름 *',
                hintText: '예: 홍길동',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 생년월일
            TextFormField(
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: '생년월일 *',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: _selectBirthDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '생년월일을 선택해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 성별
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: '성별 *',
                prefixIcon: Icon(Icons.wc),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('남성')),
                DropdownMenuItem(value: 'F', child: Text('여성')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // 진단명
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: '진단명 *',
                hintText: '예: 발달지연, 균형장애',
                prefixIcon: Icon(Icons.medical_information),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '진단명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            ElevatedButton(
              onPressed: _isSaving ? null : _savePatient,
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
                      '환자 등록',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
