import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../constants/app_theme.dart';

/// Firebase 연결 테스트 화면
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _testResult = '테스트를 시작하려면 아래 버튼을 눌러주세요.';
  bool _connectionSuccess = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = '🔄 Firebase 연결 테스트 중...\n\n'
          '프로젝트: rehab-nexus-korea\n'
          '리전: asia-northeast3 (Seoul)';
    });

    try {
      if (kDebugMode) {
        print('🔵 Firebase 연결 테스트 시작');
      }
      
      final isConnected = await _firestoreService.checkConnection();
      
      if (mounted) {
        setState(() {
          _connectionSuccess = isConnected;
          _testResult = isConnected
              ? '✅ Firebase 연결 성공!\n\n'
                  '프로젝트: rehab-nexus-korea\n'
                  '리전: asia-northeast3 (Seoul)\n'
                  '상태: 정상 연결됨'
              : '❌ Firebase 연결 실패\n\n'
                  '브라우저 콘솔(F12)에서 상세 오류를 확인하세요.\n\n'
                  '가능한 원인:\n'
                  '• Firebase 초기화 오류\n'
                  '• 네트워크 연결 문제\n'
                  '• CORS 설정 문제';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Firebase 연결 테스트 예외 발생');
        print('오류: $e');
        print('스택: $stackTrace');
      }
      
      if (mounted) {
        setState(() {
          _connectionSuccess = false;
          _testResult = '❌ 연결 오류 발생\n\n'
              '오류 타입: ${e.runtimeType}\n'
              '오류 메시지: $e\n\n'
              '브라우저 콘솔(F12)에서 상세 정보를 확인하세요.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testCreateData() async {
    setState(() {
      _isLoading = true;
      _testResult = '🔄 테스트 데이터 생성 중...';
    });

    try {
      // 테스트 환자 데이터 생성
      final patientData = {
        'organization_id': 'org_test_001',
        'patient_code': 'TEST_001',
        'name': '테스트 환자',
        'birth_date': Timestamp.fromDate(DateTime(2016, 3, 15)),
        'gender': 'M',
        'diagnosis': ['발달지연 테스트'],
        'status': 'ACTIVE',
      };

      final patientId = await _firestoreService.createPatient(patientData);

      setState(() {
        _connectionSuccess = true;
        _testResult = '✅ 테스트 데이터 생성 성공!\n'
            '환자 ID: $patientId\n'
            '이름: 테스트 환자\n'
            '생년월일: 2016-03-15';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _testResult = '❌ 데이터 생성 실패: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testReadData() async {
    setState(() {
      _isLoading = true;
      _testResult = '🔄 데이터 조회 중...';
    });

    try {
      final patients = await _firestoreService.getPatientsByOrganization('org_test_001');

      setState(() {
        _connectionSuccess = true;
        _testResult = '✅ 데이터 조회 성공!\n'
            '조회된 환자 수: ${patients.length}명\n\n'
            '${patients.isEmpty ? '데이터가 없습니다.' : patients.map((p) => '- ${p['name']} (${p['patient_code']})').join('\n')}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _testResult = '❌ 데이터 조회 실패: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateAppointment() async {
    setState(() {
      _isLoading = true;
      _testResult = '🔄 예약 데이터 생성 중...';
    });

    try {
      final appointmentData = {
        'patient_id': 'test_patient_001',
        'patient_name': '테스트 환자',
        'guardian_id': 'test_guardian_001',
        'therapist_id': 'test_therapist_001',
        'therapist_name': '테스트 치료사',
        'appointment_date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'time_slot': '10:00-11:00',
        'status': 'PENDING',
        'notes': 'Firebase 연결 테스트 예약',
      };

      final appointmentId = await _firestoreService.createAppointment(appointmentData);

      setState(() {
        _connectionSuccess = true;
        _testResult = '✅ 예약 데이터 생성 성공!\n'
            '예약 ID: $appointmentId\n'
            '환자: 테스트 환자\n'
            '시간: 10:00-11:00\n'
            '상태: 승인 대기';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _testResult = '❌ 예약 생성 실패: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkCollections() async {
    setState(() {
      _isLoading = true;
      _testResult = '🔄 컬렉션 통계 조회 중...';
    });

    try {
      final patientCount = await _firestoreService.getCollectionCount('patients');
      final appointmentCount = await _firestoreService.getCollectionCount('appointments');
      final attendanceCount = await _firestoreService.getCollectionCount('attendances');
      final inquiryCount = await _firestoreService.getCollectionCount('inquiries');

      setState(() {
        _connectionSuccess = true;
        _testResult = '✅ Firestore 데이터 통계\n\n'
            '📊 컬렉션별 데이터 수:\n'
            '• 환자 (patients): $patientCount개\n'
            '• 예약 (appointments): $appointmentCount개\n'
            '• 출석 (attendances): $attendanceCount개\n'
            '• 문의 (inquiries): $inquiryCount개';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _testResult = '❌ 통계 조회 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Firebase 연결 테스트'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Firebase 프로젝트 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔥 Firebase 프로젝트 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('프로젝트 ID', 'rehab-nexus-korea'),
                    _buildInfoRow('프로젝트 번호', '79236393316'),
                    _buildInfoRow('리전', 'asia-northeast3 (Seoul)'),
                    _buildInfoRow('패키지명', 'com.rehabnexus.rehab'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 테스트 결과
            Card(
              color: _connectionSuccess
                  ? Colors.green.shade50
                  : (_isLoading ? Colors.blue.shade50 : Colors.grey.shade50),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _connectionSuccess ? Icons.check_circle : Icons.info,
                            color: _connectionSuccess ? Colors.green : Colors.grey,
                          ),
                        const SizedBox(width: 8),
                        const Text(
                          '테스트 결과',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _testResult,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 테스트 버튼들
            const Text(
              '테스트 실행',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              '1. 연결 테스트',
              '🔗 Firebase 연결 상태 확인',
              Colors.blue,
              _testConnection,
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              '2. 데이터 생성 테스트',
              '➕ 테스트 환자 데이터 생성',
              Colors.green,
              _testCreateData,
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              '3. 데이터 조회 테스트',
              '📖 환자 데이터 조회',
              Colors.orange,
              _testReadData,
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              '4. 예약 생성 테스트',
              '📅 테스트 예약 생성',
              Colors.purple,
              _testCreateAppointment,
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              '5. 컬렉션 통계',
              '📊 Firestore 데이터 통계',
              Colors.teal,
              _checkCollections,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
