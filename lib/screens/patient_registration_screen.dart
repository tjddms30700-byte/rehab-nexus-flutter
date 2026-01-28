import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 환자 등록 화면 (개선 버전)
class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 기본 정보
  final TextEditingController _nameController = TextEditingController();
  String _gender = '남';
  DateTime _birthDate = DateTime(2010, 1, 1);
  final TextEditingController _phoneController = TextEditingController();
  bool _smsConsent = true;
  
  // 상세 정보 (드롭다운 확장)
  bool _showDetails = false;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _visitPathController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _visitPathController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 등록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 정보 타이틀
                    _buildSectionTitle('기본 정보'),
                    const SizedBox(height: 16),

                    // 이름
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: '이름 *',
                              border: OutlineInputBorder(),
                              hintText: '홍길동',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '이름을 입력하세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _checkDuplicateName,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('중복검색'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 성별
                    Row(
                      children: [
                        const Text('성별 *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        Radio<String>(
                          value: '남',
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                        ),
                        const Text('남'),
                        const SizedBox(width: 24),
                        Radio<String>(
                          value: '여',
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                        ),
                        const Text('여'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 생년월일
                    InkWell(
                      onTap: _selectBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '생년월일 *',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_birthDate.year}년 ${_birthDate.month}월 ${_birthDate.day}일'),
                            const Icon(Icons.calendar_today, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 연락처
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: '연락처 *',
                              border: OutlineInputBorder(),
                              hintText: '010-0000-0000',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '연락처를 입력하세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _checkDuplicatePhone,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('중복검색'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 문자 수신 동의
                    Row(
                      children: [
                        const Text('문자 수신', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        Radio<bool>(
                          value: true,
                          groupValue: _smsConsent,
                          onChanged: (value) {
                            setState(() {
                              _smsConsent = value!;
                            });
                          },
                        ),
                        const Text('동의'),
                        const SizedBox(width: 24),
                        Radio<bool>(
                          value: false,
                          groupValue: _smsConsent,
                          onChanged: (value) {
                            setState(() {
                              _smsConsent = value!;
                            });
                          },
                        ),
                        const Text('비동의'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 상세정보 입력 드롭다운
                    ExpansionTile(
                      title: const Text('상세정보 입력', style: TextStyle(fontWeight: FontWeight.bold)),
                      initiallyExpanded: _showDetails,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _showDetails = expanded;
                        });
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // 주소
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: '주소',
                                  border: OutlineInputBorder(),
                                  hintText: '서울시 강남구 테헤란로 123',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 방문 경로
                              TextFormField(
                                controller: _visitPathController,
                                decoration: const InputDecoration(
                                  labelText: '방문 경로',
                                  border: OutlineInputBorder(),
                                  hintText: '예) 지인 소개, 인터넷 검색',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 고객 메모
                              TextFormField(
                                controller: _memoController,
                                decoration: const InputDecoration(
                                  labelText: '고객 메모',
                                  border: OutlineInputBorder(),
                                  hintText: '특이사항 또는 메모',
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 등록 버튼
                    Center(
                      child: ElevatedButton(
                        onPressed: _registerPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
                        ),
                        child: const Text(
                          '환자 등록',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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
        color: Colors.blue,
      ),
    );
  }

  /// 생년월일 선택
  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  /// 이름 중복 검색
  Future<void> _checkDuplicateName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력하세요')),
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('name', isEqualTo: name)
          .get();

      if (mounted) {
        if (snapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 사용 가능한 이름입니다'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ 동일한 이름의 환자 ${snapshot.docs.length}명이 있습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    }
  }

  /// 연락처 중복 검색
  Future<void> _checkDuplicatePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연락처를 입력하세요')),
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('phone', isEqualTo: phone)
          .get();

      if (mounted) {
        if (snapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 사용 가능한 연락처입니다'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ 이미 등록된 연락처입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    }
  }

  /// 환자 등록
  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 환자 코드 생성 (P + 타임스탬프)
      final patientCode = 'P${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection('patients').add({
        'organization_id': 'org_rehab_nexus_001', // TODO: 실제 조직 ID로 변경
        'patient_code': patientCode,
        'name': _nameController.text.trim(),
        'gender': _gender == '남' ? 'M' : 'F',
        'birth_date': Timestamp.fromDate(_birthDate),
        'phone': _phoneController.text.trim(),
        'sms_consent': _smsConsent,
        'address': _addressController.text.trim(),
        'visit_path': _visitPathController.text.trim(),
        'memo': _memoController.text.trim(),
        'diagnosis': [],
        'guardian_ids': [],
        'assigned_therapist_id': '',
        'status': 'ACTIVE',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 환자가 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
