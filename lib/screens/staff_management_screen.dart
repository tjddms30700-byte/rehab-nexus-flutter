import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 직원 관리 화면
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['ADMIN', 'THERAPIST'])
          .get();

      setState(() {
        _staff = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
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
          SnackBar(content: Text('직원 목록 불러오기 실패: $e')),
        );
      }
    }
  }

  Future<void> _showAddStaffDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddStaffDialog(),
    );

    if (result != null) {
      await _saveStaff(result);
    }
  }

  Future<void> _saveStaff(Map<String, dynamic> staffData) async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        ...staffData,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('직원이 추가되었습니다')),
        );
      }

      _loadStaff();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('직원 추가 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteStaff(String staffId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('직원 삭제'),
        content: const Text('정말 이 직원을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(staffId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('직원이 삭제되었습니다')),
          );
        }

        _loadStaff();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('직원 삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 상단 액션 버튼
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        '직원 목록',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddStaffDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('직원 추가'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // 직원 목록
                Expanded(
                  child: _staff.isEmpty
                      ? const Center(
                          child: Text(
                            '등록된 직원이 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _staff.length,
                          itemBuilder: (context, index) {
                            final staff = _staff[index];
                            return _buildStaffCard(staff);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final name = staff['name'] ?? '이름 없음';
    final email = staff['email'] ?? '';
    final phone = staff['phone'] ?? '';
    final role = staff['role'] ?? 'THERAPIST';
    final status = staff['status'] ?? 'ACTIVE';
    final hireDate = staff['hire_date'] != null
        ? (staff['hire_date'] as Timestamp).toDate()
        : null;
    final canTeach = staff['can_teach'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleChip(role),
                          const SizedBox(width: 8),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (email.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.email, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      if (phone.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStaff(staff['id']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem('수업 가능', canTeach ? 'O' : 'X'),
                const SizedBox(width: 24),
                if (hireDate != null)
                  _buildInfoItem(
                    '입사일',
                    '${hireDate.year}-${hireDate.month.toString().padLeft(2, '0')}-${hireDate.day.toString().padLeft(2, '0')}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    String label;
    Color color;

    switch (role) {
      case 'ADMIN':
        label = '관리자';
        color = Colors.red;
        break;
      case 'THERAPIST':
        label = '치료사';
        color = Colors.blue;
        break;
      default:
        label = role;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label;
    Color color;

    switch (status) {
      case 'ACTIVE':
        label = '재직중';
        color = Colors.green;
        break;
      case 'RESIGNED':
        label = '퇴직';
        color = Colors.grey;
        break;
      case 'ON_LEAVE':
        label = '휴직';
        color = Colors.orange;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// 직원 추가 다이얼로그
class _AddStaffDialog extends StatefulWidget {
  const _AddStaffDialog();

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _status = 'ACTIVE';
  String _role = 'THERAPIST';
  bool _canTeach = true;
  DateTime _hireDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('직원 추가'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름 *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 재직상태
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: '재직상태',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('재직중')),
                  DropdownMenuItem(value: 'RESIGNED', child: Text('퇴직')),
                  DropdownMenuItem(value: 'ON_LEAVE', child: Text('휴직')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 전화번호
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                  hintText: '010-0000-0000',
                ),
              ),
              const SizedBox(height: 16),

              // 수업 가능 여부
              Row(
                children: [
                  const Text('수업 가능 여부'),
                  const Spacer(),
                  Switch(
                    value: _canTeach,
                    onChanged: (value) {
                      setState(() {
                        _canTeach = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 입사일
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _hireDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _hireDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '입사일',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_hireDate.year}-${_hireDate.month.toString().padLeft(2, '0')}-${_hireDate.day.toString().padLeft(2, '0')}'),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 로그인 정보
              const Text(
                '로그인 정보',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일 *',
                  border: OutlineInputBorder(),
                  hintText: 'example@example.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이메일을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 관리 권한
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: '관리 권한',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('관리자 권한')),
                  DropdownMenuItem(value: 'THERAPIST', child: Text('일반 권한')),
                ],
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
                'status': _status,
                'role': _role,
                'can_teach': _canTeach,
                'hire_date': Timestamp.fromDate(_hireDate),
              });
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
