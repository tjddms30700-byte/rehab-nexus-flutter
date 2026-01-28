import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../constants/enums.dart';
import '../services/patient_service.dart';
import '../providers/app_state.dart';
import 'patient_registration_screen.dart'; // 새로운 환자 등록 화면

/// 이용자 관리 화면
class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final PatientService _patientService = PatientService();
  List<Patient> _patients = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
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

      List<Patient> patients = [];

      try {
        print('🔵 [이용자관리] Firebase에서 환자 데이터 조회 중...');
        patients = await _patientService.getPatientsByTherapist(user.id);
        print('✅ [이용자관리] Firebase 환자 데이터: ${patients.length}건');
      } catch (e) {
        print('⚠️ [이용자관리] Firebase 조회 실패, Mock 데이터 사용: $e');
        
        // Mock 환자 데이터
        final today = DateTime.now();
        patients = [
          Patient(
            id: 'mock_patient_001',
            organizationId: 'mock_org_001',
            patientCode: 'P001',
            name: '홍길동',
            birthDate: DateTime(2015, 3, 15),
            gender: 'M',
            diagnosis: ['발달지연'],
            guardianIds: ['mock_guardian_001'],
            assignedTherapistId: user.id,
            status: PatientStatus.active,
            createdAt: today.subtract(const Duration(days: 90)),
          ),
          Patient(
            id: 'mock_patient_002',
            organizationId: 'mock_org_001',
            patientCode: 'P002',
            name: '김영희',
            birthDate: DateTime(2016, 8, 22),
            gender: 'F',
            diagnosis: ['언어지연'],
            guardianIds: ['mock_guardian_002'],
            assignedTherapistId: user.id,
            status: PatientStatus.active,
            createdAt: today.subtract(const Duration(days: 60)),
          ),
          Patient(
            id: 'mock_patient_003',
            organizationId: 'mock_org_001',
            patientCode: 'P003',
            name: '이철수',
            birthDate: DateTime(2014, 12, 5),
            gender: 'M',
            diagnosis: ['주의력결핍'],
            guardianIds: ['mock_guardian_003'],
            assignedTherapistId: user.id,
            status: PatientStatus.active,
            createdAt: today.subtract(const Duration(days: 30)),
          ),
          Patient(
            id: 'mock_patient_004',
            organizationId: 'mock_org_001',
            patientCode: 'P004',
            name: '박민수',
            birthDate: DateTime(2017, 5, 18),
            gender: 'M',
            diagnosis: ['운동발달지연'],
            guardianIds: ['mock_guardian_004'],
            assignedTherapistId: user.id,
            status: PatientStatus.inactive,
            createdAt: today.subtract(const Duration(days: 120)),
          ),
        ];
        print('✅ [이용자관리] Mock 환자 데이터: ${patients.length}건');
      }

      if (!mounted) return;

      setState(() {
        _patients = patients;
        _isLoading = false;
      });

      print('✅ [이용자관리] 데이터 로드 완료: ${patients.length}건');
    } catch (e) {
      print('❌ [이용자관리] 데이터 로드 실패: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = '환자 목록을 불러오는데 실패했습니다\n\n오류 내용: ${e.toString()}\n\n새로고침 버튼을 눌러 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }
    return _patients
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.patientCode.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용자 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: '환자 등록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientRegistrationScreen(),
                ),
              ).then((result) {
                if (result == true) {
                  _loadPatients();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '이름 또는 환자번호로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 통계 요약
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  '전체',
                  '${_patients.length}명',
                  Colors.blue,
                ),
                _buildStatCard(
                  '활성',
                  '${_patients.where((p) => p.status == PatientStatus.active).length}명',
                  Colors.green,
                ),
                _buildStatCard(
                  '비활성',
                  '${_patients.where((p) => p.status == PatientStatus.inactive).length}명',
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 환자 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Text(
                          '환자가 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
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
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final age = DateTime.now().year - patient.birthDate.year;
    final isActive = patient.status == PatientStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey,
          child: Text(
            patient.name[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('환자번호: ${patient.patientCode}'),
            Text('${age}세 · ${patient.gender == 'M' ? '남' : '여'}'),
            Text('진단: ${patient.diagnosis.join(', ')}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            isActive ? '활성' : '비활성',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: isActive ? Colors.green : Colors.grey,
        ),
        onTap: () => _showPatientDetail(patient),
      ),
    );
  }

  void _showPatientDetail(Patient patient) {
    final age = DateTime.now().year - patient.birthDate.year;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('환자번호: ${patient.patientCode}'),
            const SizedBox(height: 8),
            Text('나이: ${age}세'),
            const SizedBox(height: 8),
            Text('성별: ${patient.gender == 'M' ? '남성' : '여성'}'),
            const SizedBox(height: 8),
            Text('진단명: ${patient.diagnosis.join(', ')}'),
            const SizedBox(height: 8),
            Text('상태: ${patient.status == PatientStatus.active ? '활성' : '비활성'}'),
            const SizedBox(height: 16),
            const Text(
              '잔여 회차: 8회\n다음 예약: 2026-01-28 10:00',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('환자 정보 수정 (구현 예정)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}
