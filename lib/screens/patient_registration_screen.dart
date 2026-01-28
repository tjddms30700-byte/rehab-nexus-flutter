import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

/// 환자 등록 화면 (파일 업로드 포함)
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
  
  // 파일 업로드
  List<Map<String, dynamic>> _uploadedFiles = [];
  bool _isUploading = false;
  
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

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        for (var file in result.files) {
          if (file.bytes != null) {
            // Firebase Storage에 업로드
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('patient_documents/$fileName');

            final uploadTask = await storageRef.putData(
              file.bytes!,
              SettableMetadata(contentType: _getContentType(file.extension)),
            );

            final downloadUrl = await uploadTask.ref.getDownloadURL();

            setState(() {
              _uploadedFiles.add({
                'name': file.name,
                'url': downloadUrl,
                'size': file.size,
                'type': file.extension,
                'uploadedAt': DateTime.now(),
              });
            });
          }
        }

        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.files.length}개 파일 업로드 완료')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 업로드 실패: $e')),
        );
      }
    }
  }

  String _getContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
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
                        const Text('문자 수신 동의', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        Switch(
                          value: _smsConsent,
                          onChanged: (value) {
                            setState(() {
                              _smsConsent = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 파일 업로드 섹션
                    _buildSectionTitle('서류 첨부 (계약서, 영수증 등)'),
                    const SizedBox(height: 16),
                    
                    // 파일 업로드 버튼
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadFile,
                        icon: _isUploading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(_isUploading ? '업로드 중...' : '파일 업로드 (PDF, JPG, PNG)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 업로드된 파일 목록
                    if (_uploadedFiles.isNotEmpty)
                      ...List.generate(_uploadedFiles.length, (index) {
                        final file = _uploadedFiles[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getFileIcon(file['type']),
                              color: Colors.blue,
                            ),
                            title: Text(
                              file['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${_formatFileSize(file['size'])} · ${_formatDateTime(file['uploadedAt'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),

                    // 상세 정보 드롭다운
                    Card(
                      child: ExpansionTile(
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
                                TextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: '주소',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _visitPathController,
                                  decoration: const InputDecoration(
                                    labelText: '방문 경로',
                                    border: OutlineInputBorder(),
                                    hintText: '예: 지인 소개, 인터넷 검색',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _memoController,
                                  decoration: const InputDecoration(
                                    labelText: '고객 메모',
                                    border: OutlineInputBorder(),
                                    hintText: '특이사항이나 참고할 내용을 입력하세요',
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 등록 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRegistration,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('환자 등록', style: TextStyle(fontSize: 16)),
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }

  IconData _getFileIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

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
            const SnackBar(
              content: Text('사용 가능한 이름입니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${snapshot.docs.length}명의 동명이인이 있습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('중복 검색 실패: $e')),
        );
      }
    }
  }

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
            const SnackBar(
              content: Text('사용 가능한 연락처입니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 등록된 연락처입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('중복 검색 실패: $e')),
        );
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 환자 코드 생성 (P + timestamp)
      final patientCode = 'P${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection('patients').add({
        'patient_code': patientCode,
        'name': _nameController.text.trim(),
        'gender': _gender == '남' ? 'M' : 'F',
        'birth_date': Timestamp.fromDate(_birthDate),
        'phone': _phoneController.text.trim(),
        'sms_consent': _smsConsent,
        'address': _addressController.text.trim(),
        'visit_path': _visitPathController.text.trim(),
        'memo': _memoController.text.trim(),
        'status': 'ACTIVE',
        'uploaded_files': _uploadedFiles,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('환자가 성공적으로 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
