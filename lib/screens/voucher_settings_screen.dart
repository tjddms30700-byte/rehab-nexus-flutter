import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 바우처 설정 화면
class VoucherSettingsScreen extends StatefulWidget {
  const VoucherSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VoucherSettingsScreen> createState() => _VoucherSettingsScreenState();
}

class _VoucherSettingsScreenState extends State<VoucherSettingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('voucher_settings')
          .get();

      setState(() {
        _vouchers = snapshot.docs.map((doc) {
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
          SnackBar(content: Text('바우처 목록 불러오기 실패: $e')),
        );
      }
    }
  }

  Future<void> _showAddVoucherDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddVoucherDialog(),
    );

    if (result != null) {
      await _saveVoucher(result);
    }
  }

  Future<void> _editVoucher(Map<String, dynamic> voucher) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddVoucherDialog(existingVoucher: voucher),
    );

    if (result != null) {
      await _updateVoucher(voucher['id'], result);
    }
  }

  Future<void> _saveVoucher(Map<String, dynamic> voucherData) async {
    try {
      await FirebaseFirestore.instance.collection('voucher_settings').add({
        ...voucherData,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('바우처가 추가되었습니다')),
        );
      }

      _loadVouchers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('바우처 추가 실패: $e')),
        );
      }
    }
  }

  Future<void> _updateVoucher(String voucherId, Map<String, dynamic> voucherData) async {
    try {
      await FirebaseFirestore.instance
          .collection('voucher_settings')
          .doc(voucherId)
          .update({
        ...voucherData,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('바우처가 수정되었습니다')),
        );
      }

      _loadVouchers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('바우처 수정 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteVoucher(String voucherId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('바우처 삭제'),
        content: const Text('정말 이 바우처를 삭제하시겠습니까?'),
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
            .collection('voucher_settings')
            .doc(voucherId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('바우처가 삭제되었습니다')),
          );
        }

        _loadVouchers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('바우처 삭제 실패: $e')),
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
                        '바우처 프로그램 목록',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddVoucherDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('바우처 추가'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // 바우처 목록
                Expanded(
                  child: _vouchers.isEmpty
                      ? const Center(
                          child: Text(
                            '등록된 바우처가 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _vouchers.length,
                          itemBuilder: (context, index) {
                            final voucher = _vouchers[index];
                            return _buildVoucherCard(voucher);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final programName = voucher['program_name'] ?? '프로그램명 없음';
    final className = voucher['class_name'] ?? '';
    final sessions = voucher['sessions'] ?? 0;
    final baseAmount = voucher['base_amount'] ?? 0;
    final supportPerSession = voucher['support_per_session'] ?? 0;
    final selfPayment = voucher['self_payment'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    programName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editVoucher(voucher),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteVoucher(voucher['id']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow('수업', className),
            const SizedBox(height: 8),
            _buildInfoRow('회차', '$sessions회'),
            const SizedBox(height: 8),
            _buildInfoRow('기본금', '${_formatNumber(baseAmount)}원'),
            const SizedBox(height: 8),
            _buildInfoRow('회당 지원금', '${_formatNumber(supportPerSession)}원'),
            const SizedBox(height: 8),
            _buildInfoRow('본인 부담금', '${_formatNumber(selfPayment)}원'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatNumber(num number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// 바우처 추가/수정 다이얼로그
class _AddVoucherDialog extends StatefulWidget {
  final Map<String, dynamic>? existingVoucher;
  
  const _AddVoucherDialog({this.existingVoucher});

  @override
  State<_AddVoucherDialog> createState() => _AddVoucherDialogState();
}

class _AddVoucherDialogState extends State<_AddVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _sessionsController = TextEditingController();
  final TextEditingController _baseAmountController = TextEditingController();
  final TextEditingController _supportPerSessionController = TextEditingController();
  final TextEditingController _selfPaymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingVoucher != null) {
      _programNameController.text = widget.existingVoucher!['program_name'] ?? '';
      _classNameController.text = widget.existingVoucher!['class_name'] ?? '';
      _sessionsController.text = (widget.existingVoucher!['sessions'] ?? 0).toString();
      _baseAmountController.text = (widget.existingVoucher!['base_amount'] ?? 0).toString();
      _supportPerSessionController.text = (widget.existingVoucher!['support_per_session'] ?? 0).toString();
      _selfPaymentController.text = (widget.existingVoucher!['self_payment'] ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _classNameController.dispose();
    _sessionsController.dispose();
    _baseAmountController.dispose();
    _supportPerSessionController.dispose();
    _selfPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('바우처 프로그램 추가'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 바우처 프로그램명
              TextFormField(
                controller: _programNameController,
                decoration: const InputDecoration(
                  labelText: '바우처 프로그램명 *',
                  border: OutlineInputBorder(),
                  hintText: '예) 장애인스포츠바우처',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '프로그램명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 수업명
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: '수업명 *',
                  border: OutlineInputBorder(),
                  hintText: '예) 물리치료 프로그램',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '수업명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 회차
              TextFormField(
                controller: _sessionsController,
                decoration: const InputDecoration(
                  labelText: '회차 *',
                  border: OutlineInputBorder(),
                  hintText: '예) 10',
                  suffixText: '회',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '회차를 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 기본금
              TextFormField(
                controller: _baseAmountController,
                decoration: const InputDecoration(
                  labelText: '기본금 *',
                  border: OutlineInputBorder(),
                  hintText: '예) 500000',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '기본금을 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 회당 지원금
              TextFormField(
                controller: _supportPerSessionController,
                decoration: const InputDecoration(
                  labelText: '회당 지원금 *',
                  border: OutlineInputBorder(),
                  hintText: '예) 45000',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '회당 지원금을 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 본인 부담금
              TextFormField(
                controller: _selfPaymentController,
                decoration: const InputDecoration(
                  labelText: '본인 부담금 *',
                  border: OutlineInputBorder(),
                  hintText: '예) 5000',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '본인 부담금을 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
                  }
                  return null;
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
                'program_name': _programNameController.text.trim(),
                'class_name': _classNameController.text.trim(),
                'sessions': int.parse(_sessionsController.text.trim()),
                'base_amount': int.parse(_baseAmountController.text.trim()),
                'support_per_session': int.parse(_supportPerSessionController.text.trim()),
                'self_payment': int.parse(_selfPaymentController.text.trim()),
              });
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
