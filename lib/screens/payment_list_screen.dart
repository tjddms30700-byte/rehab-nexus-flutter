import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../providers/app_state.dart';
import 'payment_registration_screen.dart';

/// 수납 관리 화면
class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final _paymentService = PaymentService();
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // 필터 옵션
  bool _showOnlyActualPayments = false;  // 실제 결제 건만 표시
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  /// 결제 내역 로드
  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final payments = await _paymentService.getPaymentsByOrganization(
        currentUser.organizationId,
      );

      if (mounted) {
        setState(() {
          _payments = payments;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '결제 내역 로드 실패: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 필터 적용
  void _applyFilters() {
    var filtered = List<Payment>.from(_payments);

    // 실제 결제 건만 표시
    if (_showOnlyActualPayments) {
      filtered = filtered.where((p) => p.isActualPayment).toList();
    }

    // 날짜 필터
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((p) {
        return p.createdAt.isAfter(_startDate!) &&
               p.createdAt.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      _filteredPayments = filtered;
    });
  }

  /// 통계 계산
  Map<String, dynamic> _calculateStatistics() {
    final actualPayments = _filteredPayments.where((p) => p.isActualPayment);
    
    final totalAmount = actualPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.finalAmount,
    );

    final cashAmount = actualPayments
        .where((p) => p.paymentMethod == PaymentMethod.cash)
        .fold<double>(0, (sum, p) => sum + p.finalAmount);

    final cardAmount = actualPayments
        .where((p) => p.paymentMethod == PaymentMethod.card)
        .fold<double>(0, (sum, p) => sum + p.finalAmount);

    final transferAmount = actualPayments
        .where((p) => p.paymentMethod == PaymentMethod.transfer)
        .fold<double>(0, (sum, p) => sum + p.finalAmount);

    return {
      'total': totalAmount,
      'count': actualPayments.length,
      'cash': cashAmount,
      'card': cardAmount,
      'transfer': transferAmount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수납 관리'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentRegistrationScreen(),
            ),
          );
          if (result == true) {
            _loadPayments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('수납 등록'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildStatisticsCard(),
                    _buildFilterBar(),
                    Expanded(child: _buildPaymentList()),
                  ],
                ),
    );
  }

  /// 통계 카드
  Widget _buildStatisticsCard() {
    final stats = _calculateStatistics();
    final numberFormat = NumberFormat('#,###');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '결제 통계 (실제 결제 건)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  '총 결제액',
                  '${numberFormat.format(stats['total'])}원',
                  Colors.green,
                ),
                _buildStatItem(
                  '결제 건수',
                  '${stats['count']}건',
                  Colors.blue,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPaymentMethodStat('현금', stats['cash'] as double),
                _buildPaymentMethodStat('카드', stats['card'] as double),
                _buildPaymentMethodStat('계좌이체', stats['transfer'] as double),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 통계 항목
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 결제 방식별 통계
  Widget _buildPaymentMethodStat(String label, double amount) {
    final numberFormat = NumberFormat('#,###');
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${numberFormat.format(amount)}원',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 필터 바
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('실제 결제 건만 표시'),
                  subtitle: const Text('현금/카드/계좌이체만'),
                  value: _showOnlyActualPayments,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyActualPayments = value ?? false;
                      _applyFilters();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _showDateRangePicker,
                tooltip: '기간 선택',
              ),
            ],
          ),
          if (_startDate != null && _endDate != null)
            Chip(
              label: Text(
                '${DateFormat('yyyy-MM-dd').format(_startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
              ),
              onDeleted: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _applyFilters();
                });
              },
            ),
        ],
      ),
    );
  }

  /// 날짜 범위 선택
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  /// 결제 목록
  Widget _buildPaymentList() {
    if (_filteredPayments.isEmpty) {
      return const Center(
        child: Text('결제 내역이 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  /// 결제 카드
  Widget _buildPaymentCard(Payment payment) {
    final numberFormat = NumberFormat('#,###');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPaymentMethodColor(payment.paymentMethod),
          child: Icon(
            _getPaymentMethodIcon(payment.paymentMethod),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          payment.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${DateFormat('yyyy-MM-dd HH:mm').format(payment.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPaymentMethodColor(payment.paymentMethod).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.paymentMethodName,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getPaymentMethodColor(payment.paymentMethod),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (payment.memo != null && payment.memo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '💬 ${payment.memo}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (payment.discount > 0)
              Text(
                '${numberFormat.format(payment.amount)}원',
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            Text(
              '${numberFormat.format(payment.finalAmount)}원',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (payment.useVoucher && payment.voucherSessions != null)
              Text(
                '횟수권 -${payment.voucherSessions}회',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  /// 결제 방식 아이콘
  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.transfer:
        return Icons.account_balance;
      case PaymentMethod.voucher:
        return Icons.confirmation_number;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  /// 결제 방식 색상
  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.transfer:
        return Colors.purple;
      case PaymentMethod.voucher:
        return Colors.orange;
      case PaymentMethod.other:
        return Colors.grey;
    }
  }

  /// 결제 상세 보기
  void _showPaymentDetails(Payment payment) {
    final numberFormat = NumberFormat('#,###');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(payment.patientName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('결제 내용', payment.description),
                _buildDetailRow('결제 방식', payment.paymentMethodName),
                _buildDetailRow('담당자', payment.therapistName),
                const Divider(),
                _buildDetailRow('결제 금액', '${numberFormat.format(payment.amount)}원'),
                if (payment.discount > 0)
                  _buildDetailRow('할인 금액', '-${numberFormat.format(payment.discount)}원', color: Colors.red),
                _buildDetailRow(
                  '최종 금액',
                  '${numberFormat.format(payment.finalAmount)}원',
                  isBold: true,
                  color: Colors.green,
                ),
                const Divider(),
                _buildDetailRow(
                  '결제 일시',
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(payment.createdAt),
                ),
                if (payment.useVoucher && payment.voucherSessions != null)
                  _buildDetailRow('횟수권 차감', '${payment.voucherSessions}회'),
                if (payment.memo != null && payment.memo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '메모',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(payment.memo!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  /// 상세 정보 행
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 위젯
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '오류가 발생했습니다',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPayments,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
