import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/invite.dart';
import '../models/patient.dart';
import '../services/invite_service.dart';
import '../providers/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 센터장 초대 관리 화면
class InviteManagementScreen extends StatefulWidget {
  const InviteManagementScreen({super.key});

  @override
  State<InviteManagementScreen> createState() => _InviteManagementScreenState();
}

class _InviteManagementScreenState extends State<InviteManagementScreen> {
  final _inviteService = InviteService();
  
  List<Invite> _invites = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  
  // 필터
  InviteStatus? _statusFilter;
  String? _roleFilter;
  
  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  /// 초대 목록 및 통계 로드
  Future<void> _loadInvites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final centerId = appState.currentUser?.organizationId ?? '';

      // 초대 목록 조회
      final invites = await _inviteService.getInvitesByCenter(
        centerId: centerId,
        status: _statusFilter,
      );

      // 역할 필터 적용
      List<Invite> filteredInvites = invites;
      if (_roleFilter != null) {
        filteredInvites = invites.where((invite) => invite.role == _roleFilter).toList();
      }

      // 통계 조회
      final stats = await _inviteService.getInviteStatsByCenter(centerId);

      setState(() {
        _invites = filteredInvites;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 초대 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 초대 생성 다이얼로그
  Future<void> _showCreateInviteDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _CreateInviteDialog(
        onInviteCreated: _loadInvites,
      ),
    );
  }

  /// 초대 코드 복사
  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드가 복사되었습니다')),
    );
  }

  /// 초대 취소
  Future<void> _cancelInvite(String inviteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 취소'),
        content: const Text('이 초대를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _inviteService.cancelInvite(inviteId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대가 취소되었습니다')),
        );
        _loadInvites();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대 취소에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 초대 재발송
  Future<void> _resendInvite(String inviteId) async {
    final result = await _inviteService.resendInvite(inviteId);
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대가 재발송되었습니다')),
      );
      _loadInvites();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? '재발송에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('초대 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvites,
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI 요약
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('전체', _stats['total'] ?? 0, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('대기', _stats['invited'] ?? 0, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('완료', _stats['accepted'] ?? 0, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('만료', _stats['expired'] ?? 0, Colors.red)),
              ],
            ),
          ),

          // 필터 및 생성 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 상태 필터
                Expanded(
                  child: DropdownButtonFormField<InviteStatus?>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: '상태',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('전체')),
                      DropdownMenuItem(value: InviteStatus.invited, child: Text('대기')),
                      DropdownMenuItem(value: InviteStatus.accepted, child: Text('완료')),
                      DropdownMenuItem(value: InviteStatus.expired, child: Text('만료')),
                      DropdownMenuItem(value: InviteStatus.cancelled, child: Text('취소')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadInvites();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // 역할 필터
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _roleFilter,
                    decoration: const InputDecoration(
                      labelText: '역할',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('전체')),
                      DropdownMenuItem(value: 'therapist', child: Text('치료사')),
                      DropdownMenuItem(value: 'guardian', child: Text('보호자')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _roleFilter = value;
                      });
                      _loadInvites();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // 초대 생성 버튼
                ElevatedButton.icon(
                  onPressed: _showCreateInviteDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('초대'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // 초대 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _invites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '초대 내역이 없습니다',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _invites.length,
                        itemBuilder: (context, index) {
                          final invite = _invites[index];
                          return _buildInviteCard(invite);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 통계 카드
  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 초대 카드
  Widget _buildInviteCard(Invite invite) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(invite.status),
          child: Icon(
            _getStatusIcon(invite.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          invite.email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(invite.roleDisplayName, Colors.blue),
                const SizedBox(width: 8),
                _buildChip(invite.statusDisplayName, _getStatusColor(invite.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '생성: ${_formatDate(invite.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상세 정보
                if (invite.patientName != null) ...[
                  _buildDetailRow('연결 환자', invite.patientName!),
                  const Divider(),
                ],
                _buildDetailRow('생성자', invite.createdByName ?? '알 수 없음'),
                _buildDetailRow('만료일', _formatDate(invite.expiresAt)),
                if (invite.usedAt != null)
                  _buildDetailRow('사용일', _formatDate(invite.usedAt!)),
                
                const SizedBox(height: 16),
                
                // 액션 버튼들
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 재발송 (대기 중인 초대만)
                    if (invite.status == InviteStatus.invited && !invite.isExpired)
                      OutlinedButton.icon(
                        onPressed: () => _resendInvite(invite.id),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('재발송'),
                      ),
                    
                    // 취소 (대기 중인 초대만)
                    if (invite.status == InviteStatus.invited)
                      OutlinedButton.icon(
                        onPressed: () => _cancelInvite(invite.id),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('취소'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    
                    // 재생성 (만료/취소된 초대)
                    if (invite.status == InviteStatus.expired || 
                        invite.status == InviteStatus.cancelled)
                      ElevatedButton.icon(
                        onPressed: () => _resendInvite(invite.id),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('재생성'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 칩 위젯
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 상세 정보 행
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 색상
  Color _getStatusColor(InviteStatus status) {
    switch (status) {
      case InviteStatus.invited:
        return Colors.orange;
      case InviteStatus.accepted:
        return Colors.green;
      case InviteStatus.expired:
        return Colors.red;
      case InviteStatus.cancelled:
        return Colors.grey;
    }
  }

  /// 상태 아이콘
  IconData _getStatusIcon(InviteStatus status) {
    switch (status) {
      case InviteStatus.invited:
        return Icons.schedule;
      case InviteStatus.accepted:
        return Icons.check_circle;
      case InviteStatus.expired:
        return Icons.error;
      case InviteStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// 날짜 포맷
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 초대 생성 다이얼로그
class _CreateInviteDialog extends StatefulWidget {
  final VoidCallback onInviteCreated;

  const _CreateInviteDialog({
    required this.onInviteCreated,
  });

  @override
  State<_CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<_CreateInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _inviteService = InviteService();
  
  String _role = 'therapist';
  Patient? _selectedPatient;
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _createdCode;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// 환자 목록 로드
  Future<void> _loadPatients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      setState(() {
        _patients = snapshot.docs
            .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('❌ 환자 목록 로드 실패: $e');
    }
  }

  /// 초대 생성
  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 보호자 초대 시 환자 선택 필수
    if (_role == 'guardian' && _selectedPatient == null) {
      setState(() {
        _errorMessage = '보호자 초대 시 연결할 환자를 선택해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser!;

      final result = await _inviteService.createInvite(
        email: _emailController.text.trim(),
        role: _role,
        centerId: user.organizationId,
        centerName: '센터',
        createdByUid: user.id,
        createdByName: user.name,
        patientId: _selectedPatient?.id,
        patientName: _selectedPatient?.name,
      );

      if (result['success'] == true) {
        setState(() {
          _createdCode = result['code'];
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? '초대 생성 실패';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdCode != null) {
      return _buildSuccessDialog();
    }

    return AlertDialog(
      title: const Text('초대 생성'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일 *',
                  hintText: 'user@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!value.contains('@')) {
                    return '올바른 이메일 형식이 아닙니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 역할
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: '역할 *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'therapist', child: Text('치료사')),
                  DropdownMenuItem(value: 'guardian', child: Text('보호자')),
                ],
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                    _selectedPatient = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 환자 선택 (보호자 초대 시)
              if (_role == 'guardian') ...[
                DropdownButtonFormField<Patient>(
                  value: _selectedPatient,
                  decoration: const InputDecoration(
                    labelText: '연결 환자 *',
                    border: OutlineInputBorder(),
                  ),
                  items: _patients.map((patient) {
                    return DropdownMenuItem(
                      value: patient,
                      child: Text(patient.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPatient = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 오류 메시지
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
          onPressed: _isLoading ? null : _createInvite,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('생성'),
        ),
      ],
    );
  }

  /// 성공 다이얼로그
  Widget _buildSuccessDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          const Text('초대 생성 완료'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('초대 코드가 생성되었습니다'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _createdCode!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _createdCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('코드가 복사되었습니다')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '이메일로 초대장이 발송되었습니다',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onInviteCreated();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
