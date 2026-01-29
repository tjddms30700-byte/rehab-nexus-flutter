import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'patient_registration_screen.dart';

/// 이용자 관리 화면 (파일 업로드, 수정, 삭제, 프로그램 현황 포함)
class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  List<Map<String, dynamic>> _patients = [];
  String _searchQuery = '';
  bool _isLoading = false;

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
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('환자 목록 불러오기 실패: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }
    return _patients.where((patient) {
      final name = patient['name'] ?? '';
      final code = patient['patient_code'] ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _showPatientDetails(Map<String, dynamic> patient) async {
    await showDialog(
      context: context,
      builder: (context) => _PatientDetailDialog(
        patient: patient,
        onUpdated: _loadPatients,
      ),
    );
  }

  Future<void> _deletePatient(Map<String, dynamic> patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 삭제'),
        content: Text('${patient['name']}님을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patient['id'])
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('환자가 삭제되었습니다')),
          );
        }
        _loadPatients();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용자 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientRegistrationScreen(),
                ),
              );
              if (result == true) {
                _loadPatients();
              }
            },
            tooltip: '환자 등록',
          ),
        ],
      ),
      body: Column(
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

          // 통계 카드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '전체 환자',
                    _patients.length.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '활성 환자',
                    _patients.where((p) => p['status'] == 'ACTIVE').length.toString(),
                    Colors.green,
                  ),
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
                    ? const Center(
                        child: Text(
                          '등록된 환자가 없습니다',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] ?? '이름 없음';
    final code = patient['patient_code'] ?? '';
    final gender = patient['gender'] == 'M' ? '남' : '여';
    final birthDate = patient['birth_date'] != null
        ? (patient['birth_date'] as Timestamp).toDate()
        : null;
    final age = birthDate != null ? DateTime.now().year - birthDate.year : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            name[0],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$code | $gender | $age세'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showPatientDetails(patient),
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePatient(patient),
              tooltip: '삭제',
            ),
          ],
        ),
        onTap: () => _showPatientDetails(patient),
      ),
    );
  }
}

/// 환자 상세/수정 다이얼로그
class _PatientDetailDialog extends StatefulWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onUpdated;

  const _PatientDetailDialog({
    required this.patient,
    required this.onUpdated,
  });

  @override
  State<_PatientDetailDialog> createState() => _PatientDetailDialogState();
}

class _PatientDetailDialogState extends State<_PatientDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _memoController;
  
  List<Map<String, dynamic>> _uploadedFiles = [];
  List<Map<String, dynamic>> _programs = [];
  bool _isUploading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(text: widget.patient['name']);
    _phoneController = TextEditingController(text: widget.patient['phone']);
    _addressController = TextEditingController(text: widget.patient['address']);
    _memoController = TextEditingController(text: widget.patient['memo']);
    
    _uploadedFiles = List<Map<String, dynamic>>.from(widget.patient['uploaded_files'] ?? []);
    _loadPrograms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patient_programs')
          .where('patient_id', isEqualTo: widget.patient['id'])
          .get();

      setState(() {
        _programs = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      print('프로그램 불러오기 실패: $e');
    }
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
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('patient_documents/${widget.patient['id']}/$fileName');

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
                'uploadedAt': DateTime.now().toIso8601String(),
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

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient['id'])
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'memo': _memoController.text.trim(),
        'uploaded_files': _uploadedFiles,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다')),
        );
        widget.onUpdated();
        Navigator.pop(context);
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
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Text(
                  widget.patient['name'] ?? '환자 정보',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 탭
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '기본 정보'),
                Tab(text: '서류 관리'),
                Tab(text: '프로그램 현황'),
              ],
            ),
            const SizedBox(height: 16),

            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildDocumentsTab(),
                  _buildProgramsTab(),
                ],
              ),
            ),

            // 저장 버튼
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '연락처',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: '주소',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              labelText: '메모',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickAndUploadFile,
          icon: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(_isUploading ? '업로드 중...' : '파일 업로드'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _uploadedFiles.isEmpty
              ? const Center(child: Text('업로드된 파일이 없습니다'))
              : ListView.builder(
                  itemCount: _uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _uploadedFiles[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(_getFileIcon(file['type'])),
                        title: Text(file['name']),
                        subtitle: Text(_formatFileSize(file['size'])),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _uploadedFiles.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgramsTab() {
    return _programs.isEmpty
        ? const Center(child: Text('구매한 프로그램이 없습니다'))
        : ListView.builder(
            itemCount: _programs.length,
            itemBuilder: (context, index) {
              final program = _programs[index];
              final programName = program['program_name'] ?? '프로그램';
              final totalSessions = program['total_sessions'] ?? 0;
              final usedSessions = program['used_sessions'] ?? 0;
              final remainingSessions = totalSessions - usedSessions;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: usedSessions / totalSessions,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          remainingSessions > 0 ? Colors.blue : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('전체: $totalSessions회'),
                          Text('사용: $usedSessions회'),
                          Text(
                            '남음: $remainingSessions회',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: remainingSessions > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
}
