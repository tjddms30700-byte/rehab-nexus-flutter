import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_theme.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

/// 수납 내역 조회 화면
class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = false;
  
  // 필터 상태
  String _selectedPeriod = '전체'; // 전체, 오늘, 이번주, 이번달
  String _selectedPaymentMethod = '전체'; // 전체, 현금, 카드, 계좌이체
  String _selectedStatus = '전체'; // 전체, 완료, 대기, 취소
  
  // 통계 데이터
  int _totalPayments = 0;
  int _totalAmount = 0;
  int _cashAmount = 0;
  int _cardAmount = 0;
  int _transferAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock 데이터 (Firebase 연동 전)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final now = DateTime.now();
      
      if (!mounted) return;
      
      setState(() {
        _payments = [
          {
            'id': 'payment_001',
            'patient_name': '홍길동',
            'patient_code': 'P001',
            'amount': 300000,
            'payment_method': '카드',
            'payment_date': now.subtract(const Duration(days: 1)),
            'status': '완료',
            'session_count': 8,
            'discount': 0,
            'notes': '12월 정기 수납',
          },
          {
            'id': 'payment_002',
            'patient_name': '김영희',
            'patient_code': 'P002',
            'amount': 250000,
            'payment_method': '현금',
            'payment_date': now.subtract(const Duration(days: 2)),
            'status': '완료',
            'session_count': 8,
            'discount': 50000,
            'notes': '형제 할인 적용',
          },
          {
            'id': 'payment_003',
            'patient_name': '박철수',
            'patient_code': 'P003',
            'amount': 350000,
            'payment_method': '계좌이체',
            'payment_date': now.subtract(const Duration(days: 5)),
            'status': '완료',
            'session_count': 10,
            'discount': 0,
            'notes': '',
          },
          {
            'id': 'payment_004',
            'patient_name': '이민수',
            'patient_code': 'P004',
            'amount': 300000,
            'payment_method': '카드',
            'payment_date': now.subtract(const Duration(days: 7)),
            'status': '완료',
            'session_count': 8,
            'discount': 0,
            'notes': '',
          },
          {
            'id': 'payment_005',
            'patient_name': '정수영',
            'patient_code': 'P005',
            'amount': 0,
            'payment_method': '미정',
            'payment_date': now,
            'status': '대기',
            'session_count': 8,
            'discount': 0,
            'notes': '수납 대기 중',
          },
        ];
        
        _calculateStatistics();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('수납 내역 로딩 오류: $e');
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    _totalPayments = 0;
    _totalAmount = 0;
    _cashAmount = 0;
    _cardAmount = 0;
    _transferAmount = 0;
    
    for (var payment in _getFilteredPayments()) {
      if (payment['status'] == '완료') {
        _totalPayments++;
        final amount = payment['amount'] as int;
        _totalAmount += amount;
        
        switch (payment['payment_method']) {
          case '현금':
            _cashAmount += amount;
            break;
          case '카드':
            _cardAmount += amount;
            break;
          case '계좌이체':
            _transferAmount += amount;
            break;
        }
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredPayments() {
    var filtered = _payments.where((payment) {
      // 기간 필터
      if (_selectedPeriod != '전체') {
        final paymentDate = payment['payment_date'] as DateTime;
        final now = DateTime.now();
        
        switch (_selectedPeriod) {
          case '오늘':
            if (paymentDate.day != now.day ||
                paymentDate.month != now.month ||
                paymentDate.year != now.year) {
              return false;
            }
            break;
          case '이번주':
            final weekAgo = now.subtract(const Duration(days: 7));
            if (paymentDate.isBefore(weekAgo)) {
              return false;
            }
            break;
          case '이번달':
            if (paymentDate.month != now.month ||
                paymentDate.year != now.year) {
              return false;
            }
            break;
        }
      }
      
      // 결제수단 필터
      if (_selectedPaymentMethod != '전체' &&
          payment['payment_method'] != _selectedPaymentMethod) {
        return false;
      }
      
      // 상태 필터
      if (_selectedStatus != '전체' &&
          payment['status'] != _selectedStatus) {
        return false;
      }
      
      return true;
    }).toList();
    
    // 날짜 역순 정렬
    filtered.sort((a, b) {
      final dateA = a['payment_date'] as DateTime;
      final dateB = b['payment_date'] as DateTime;
      return dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPayments = _getFilteredPayments();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 수납 내역'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showPaymentDialog,
            tooltip: '수납 등록',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: 통계 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('통계 화면은 개발 중입니다')),
              );
            },
            tooltip: '통계 보기',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 통계 요약 카드
                Container(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('총 수납', '$_totalPayments건'),
                          _buildStatItem(
                            '총 금액',
                            '${NumberFormat('#,###').format(_totalAmount)}원',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            '현금',
                            '${NumberFormat('#,###').format(_cashAmount)}원',
                            color: Colors.green,
                          ),
                          _buildStatItem(
                            '카드',
                            '${NumberFormat('#,###').format(_cardAmount)}원',
                            color: Colors.blue,
                          ),
                          _buildStatItem(
                            '계좌이체',
                            '${NumberFormat('#,###').format(_transferAmount)}원',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 필터 버튼
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: '전체',
                          isSelected: _selectedPeriod == '전체',
                          onTap: () => setState(() {
                            _selectedPeriod = '전체';
                            _calculateStatistics();
                          }),
                        ),
                        _buildFilterChip(
                          label: '오늘',
                          isSelected: _selectedPeriod == '오늘',
                          onTap: () => setState(() {
                            _selectedPeriod = '오늘';
                            _calculateStatistics();
                          }),
                        ),
                        _buildFilterChip(
                          label: '이번주',
                          isSelected: _selectedPeriod == '이번주',
                          onTap: () => setState(() {
                            _selectedPeriod = '이번주';
                            _calculateStatistics();
                          }),
                        ),
                        _buildFilterChip(
                          label: '이번달',
                          isSelected: _selectedPeriod == '이번달',
                          onTap: () => setState(() {
                            _selectedPeriod = '이번달';
                            _calculateStatistics();
                          }),
                        ),
                        const SizedBox(width: 16),
                        _buildFilterChip(
                          label: '전체',
                          isSelected: _selectedPaymentMethod == '전체',
                          onTap: () => setState(() {
                            _selectedPaymentMethod = '전체';
                            _calculateStatistics();
                          }),
                        ),
                        _buildFilterChip(
                          label: '현금',
                          isSelected: _selectedPaymentMethod == '현금',
                          onTap: () => setState(() {
                            _selectedPaymentMethod = '현금';
                            _calculateStatistics();
                          }),
                        ),
                        _buildFilterChip(
                          label: '카드',
                          isSelected: _selectedPaymentMethod == '카드',
                          onTap: () => setState(() {
                            _selectedPaymentMethod = '카드';
                            _calculateStatistics();
                          }),
                        ),
                        _buildFilterChip(
                          label: '계좌이체',
                          isSelected: _selectedPaymentMethod == '계좌이체',
                          onTap: () => setState(() {
                            _selectedPaymentMethod = '계좌이체';
                            _calculateStatistics();
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Divider(height: 1),
                
                // 수납 목록
                Expanded(
                  child: filteredPayments.isEmpty
                      ? const Center(
                          child: Text('수납 내역이 없습니다'),
                        )
                      : ListView.builder(
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = filteredPayments[index];
                            return _buildPaymentListItem(payment);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
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
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildPaymentListItem(Map<String, dynamic> payment) {
    final paymentDate = payment['payment_date'] as DateTime;
    final status = payment['status'] as String;
    final amount = payment['amount'] as int;
    
    Color statusColor;
    switch (status) {
      case '완료':
        statusColor = Colors.green;
        break;
      case '대기':
        statusColor = Colors.orange;
        break;
      case '취소':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(
            status == '완료'
                ? Icons.check_circle
                : status == '대기'
                    ? Icons.access_time
                    : Icons.cancel,
            color: statusColor,
          ),
        ),
        title: Row(
          children: [
            Text(
              payment['patient_name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${payment['patient_code']} • ${payment['session_count']}회권'),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(paymentDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (payment['discount'] > 0)
              Text(
                '할인: -${NumberFormat('#,###').format(payment['discount'])}원',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,###').format(amount)}원',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: status == '완료' ? AppTheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              payment['payment_method'],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () => _showPaymentDetail(payment),
      ),
    );
  }

  void _showPaymentDetail(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${payment['patient_name']} 수납 상세'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('환자 코드', payment['patient_code']),
              _buildDetailRow('수납 금액', '${NumberFormat('#,###').format(payment['amount'])}원'),
              _buildDetailRow('결제 수단', payment['payment_method']),
              _buildDetailRow('회권', '${payment['session_count']}회'),
              if (payment['discount'] > 0)
                _buildDetailRow(
                  '할인 금액',
                  '-${NumberFormat('#,###').format(payment['discount'])}원',
                  valueColor: Colors.red,
                ),
              _buildDetailRow('상태', payment['status']),
              _buildDetailRow(
                '수납 일시',
                DateFormat('yyyy-MM-dd HH:mm').format(payment['payment_date'] as DateTime),
              ),
              if (payment['notes'].toString().isNotEmpty)
                _buildDetailRow('비고', payment['notes']),
            ],
          ),
        ),
        actions: [
          if (payment['status'] == '대기')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment(payment);
              },
              child: const Text('수납 처리'),
            ),
          if (payment['status'] == '완료')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCancelDialog(payment);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('수납 취소'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    // TODO: 수납 등록 화면
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수납 등록'),
        content: const Text('수납 등록 기능은 개발 중입니다.\n\n환자 선택, 금액 입력, 결제 수단 선택 등의 기능이 추가될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _processPayment(Map<String, dynamic> payment) {
    // TODO: 실제 수납 처리 로직
    setState(() {
      payment['status'] = '완료';
      _calculateStatistics();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${payment['patient_name']} 수납이 완료되었습니다')),
    );
  }

  void _showCancelDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수납 취소'),
        content: Text('${payment['patient_name']}의 수납을 취소하시겠습니까?\n\n취소된 수납은 환불 처리가 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelPayment(payment);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('예, 취소'),
          ),
        ],
      ),
    );
  }

  void _cancelPayment(Map<String, dynamic> payment) {
    // TODO: 실제 수납 취소 로직
    setState(() {
      payment['status'] = '취소';
      _calculateStatistics();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${payment['patient_name']} 수납이 취소되었습니다')),
    );
  }
}
