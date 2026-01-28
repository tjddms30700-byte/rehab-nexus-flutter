import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../models/patient.dart';
import '../services/payment_service.dart';
import '../providers/app_state.dart';

/// 수납 등록 화면 (간소화 버전)
class PaymentRegistrationScreen extends StatefulWidget {
  const PaymentRegistrationScreen({super.key});

  @override
  State<PaymentRegistrationScreen> createState() => _PaymentRegistrationScreenState();
}

class _PaymentRegistrationScreenState extends State<PaymentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();
  
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController();
  final _memoController = TextEditingController();
  final _voucherSessionsController = TextEditingController();

  Patient? _selectedPatient;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _useVoucher = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _discountController.dispose();
    _memoController.dispose();
    _voucherSessionsController.dispose();
    super.dispose();
  }

  double get _finalAmount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    return amount - discount;
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 항목을 입력해주세요')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final payment = Payment(
        id: const Uuid().v4(),
        patientId: _selectedPatient!.id,
        patientName: _selectedPatient!.name,
        organizationId: currentUser.organizationId,
        therapistId: currentUser.id,
        therapistName: currentUser.name,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        discount: double.tryParse(_discountController.text) ?? 0,
        finalAmount: _finalAmount,
        paymentMethod: _selectedPaymentMethod,
        useVoucher: _useVoucher,
        voucherSessions: _useVoucher ? int.tryParse(_voucherSessionsController.text) : null,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(payment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 결제가 등록되었습니다')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 결제 등록 실패: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수납 등록'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 환자 선택
                    _buildPatientSelector(),
                    const SizedBox(height: 16),

                    // 결제 내용
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '결제 내용 *',
                        hintText: '예) 물리치료 10회권',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '결제 내용을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 금액 입력
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: '결제 금액 *',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '금액을 입력해주세요';
                              }
                              if (double.tryParse(value) == null) {
                                return '올바른 금액을 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            decoration: const InputDecoration(
                              labelText: '할인 금액',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 최종 금액
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('최종 결제 금액', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '${_finalAmount.toStringAsFixed(0)}원',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 결제 방식 선택
                    const Text('결제 방식 *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PaymentMethod.values.map((method) {
                        return ChoiceChip(
                          label: Text(_getPaymentMethodName(method)),
                          selected: _selectedPaymentMethod == method,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPaymentMethod = method;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 횟수권 사용
                    CheckboxListTile(
                      title: const Text('횟수권 사용'),
                      value: _useVoucher,
                      onChanged: (value) {
                        setState(() {
                          _useVoucher = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    if (_useVoucher) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _voucherSessionsController,
                        decoration: const InputDecoration(
                          labelText: '차감 횟수',
                          hintText: '예) 1',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 결제 요약 메모
                    TextFormField(
                      controller: _memoController,
                      decoration: const InputDecoration(
                        labelText: '결제 요약 메모',
                        hintText: '예) 김영희 횟수권 1회 차감식으로',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // 등록 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          '결제 등록',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPatientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('환자 선택 *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final patient = await _showPatientPicker();
            if (patient != null) {
              setState(() {
                _selectedPatient = patient;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedPatient?.name ?? '환자를 선택하세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedPatient == null ? Colors.grey : Colors.black,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Patient?> _showPatientPicker() async {
    return showDialog<Patient>(
      context: context,
      builder: (context) {
        return _PatientPickerDialog();
      },
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return '현금';
      case PaymentMethod.card:
        return '카드';
      case PaymentMethod.transfer:
        return '계좌이체';
      case PaymentMethod.voucher:
        return '횟수권';
      case PaymentMethod.other:
        return '기타';
    }
  }
}

/// 환자 선택 다이얼로그
class _PatientPickerDialog extends StatefulWidget {
  @override
  State<_PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<_PatientPickerDialog> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('organization_id', isEqualTo: currentUser.organizationId)
          .where('status', isEqualTo: 'active')
          .get();

      final patients = querySnapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _patients = patients;
          _filteredPatients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          return patient.name.toLowerCase().contains(query.toLowerCase()) ||
                 patient.patientCode.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '환자 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '이름 또는 환자번호로 검색',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _filterPatients,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? const Center(child: Text('환자가 없습니다'))
                      : ListView.builder(
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Text(
                                  patient.name.isNotEmpty ? patient.name[0] : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(patient.name),
                              subtitle: Text(patient.patientCode),
                              onTap: () => Navigator.pop(context, patient),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
