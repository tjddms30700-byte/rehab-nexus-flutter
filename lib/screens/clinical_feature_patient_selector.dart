import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../constants/enums.dart';
import '../providers/app_state.dart';
import 'assessment_input_screen.dart';
import 'session_record_screen.dart';
import 'goal_list_screen.dart';
import 'progress_tracking_screen.dart';
import 'content_recommendation_screen.dart';

/// 임상 기능 환자 선택 화면
class ClinicalFeaturePatientSelector extends StatefulWidget {
  final String featureType; // 'assessment', 'session', 'goals', 'progress'
  
  const ClinicalFeaturePatientSelector({
    Key? key,
    required this.featureType,
  }) : super(key: key);

  @override
  State<ClinicalFeaturePatientSelector> createState() => _ClinicalFeaturePatientSelectorState();
}

class _ClinicalFeaturePatientSelectorState extends State<ClinicalFeaturePatientSelector> {
  List<Patient> _patients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      final currentUser = appState.currentUser;
      
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('organization_id', isEqualTo: currentUser.organizationId)
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      setState(() {
        _patients = snapshot.docs.map((doc) {
          return Patient.fromFirestore(doc.data(), doc.id);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }
    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             patient.patientCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getFeatureTitle() {
    switch (widget.featureType) {
      case 'assessment':
        return '평가 입력';
      case 'session':
        return '세션 기록';
      case 'goals':
        return '목표 관리';
      case 'progress':
        return '성과 추이';
      case 'content':
        return '콘텐츠 추천';
      default:
        return '환자 선택';
    }
  }

  void _navigateToFeature(Patient patient) {
    Widget screen;
    switch (widget.featureType) {
      case 'assessment':
        screen = AssessmentInputScreen(patient: patient);
        break;
      case 'session':
        screen = SessionRecordScreen(patient: patient);
        break;
      case 'goals':
        screen = GoalListScreen(patient: patient);
        break;
      case 'progress':
        screen = ProgressTrackingScreen(patient: patient);
        break;
      case 'content':
        screen = ContentRecommendationScreen(patient: patient);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getFeatureTitle()} - 환자 선택'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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

                // 환자 목록
                Expanded(
                  child: _filteredPatients.isEmpty
                      ? const Center(
                          child: Text(
                            '등록된 환자가 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    patient.name[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  patient.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${patient.patientCode} | ${_getGenderText(patient.gender)} | ${_calculateAge(patient.birthDate)}세',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _navigateToFeature(patient),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
