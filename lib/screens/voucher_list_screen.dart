import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';

/// 바우처 정보 모델
class Voucher {
  final String id;
  final String patientId;
  final String patientName;
  final String voucherType; // 발달재활, 언어발달, 기타
  final int totalSessions; // 총 회기 수
  final int usedSessions; // 사용한 회기 수
  final int remainingSessions; // 남은 회기 수
  final DateTime startDate;
  final DateTime endDate;
  final int copaymentAmount; // 자부담금
  final String status; // ACTIVE, EXPIRED, COMPLETED

  Voucher({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.voucherType,
    required this.totalSessions,
    required this.usedSessions,
    required this.startDate,
    required this.endDate,
    required this.copaymentAmount,
    required this.status,
  }) : remainingSessions = totalSessions - usedSessions;

  double get usageRate => (usedSessions / totalSessions * 100);
}

/// 바우처 관리 화면
class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String _filterStatus = 'ALL'; // ALL, ACTIVE, EXPIRED

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  void _loadVouchers() {
    setState(() {
      _isLoading = true;
    });

    // Mock 데이터 생성
    final now = DateTime.now();
    _vouchers = [
      Voucher(
        id: 'voucher_001',
        patientId: 'patient_001',
        patientName: '홍길동',
        voucherType: '발달재활서비스',
        totalSessions: 24,
        usedSessions: 16,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        copaymentAmount: 20000,
        status: 'ACTIVE',
      ),
      Voucher(
        id: 'voucher_002',
        patientId: 'patient_002',
        patientName: '김영희',
        voucherType: '언어발달지원',
        totalSessions: 20,
        usedSessions: 8,
        startDate: DateTime(now.year, 3, 1),
        endDate: DateTime(now.year, 12, 31),
        copaymentAmount: 15000,
        status: 'ACTIVE',
      ),
      Voucher(
        id: 'voucher_003',
        patientId: 'patient_003',
        patientName: '이철수',
        voucherType: '발달재활서비스',
        totalSessions: 24,
        usedSessions: 24,
        startDate: DateTime(now.year - 1, 1, 1),
        endDate: DateTime(now.year - 1, 12, 31),
        copaymentAmount: 25000,
        status: 'COMPLETED',
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  List<Voucher> get _filteredVouchers {
    if (_filterStatus == 'ALL') return _vouchers;
    return _vouchers.where((v) => v.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('바우처 관리'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddVoucherDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVouchers.isEmpty
                    ? _buildEmptyState()
                    : _buildVoucherList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final active = _vouchers.where((v) => v.status == 'ACTIVE').length;
    final totalSessions = _vouchers
        .where((v) => v.status == 'ACTIVE')
        .fold(0, (sum, v) => sum + v.remainingSessions);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('활성 바우처', '$active', Colors.orange),
          _buildSummaryItem('남은 회기', '$totalSessions', Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
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
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('전체', 'ALL'),
          const SizedBox(width: 8),
          _buildFilterChip('활성', 'ACTIVE'),
          const SizedBox(width: 8),
          _buildFilterChip('완료', 'COMPLETED'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '바우처가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredVouchers.length,
      itemBuilder: (context, index) {
        return _buildVoucherCard(_filteredVouchers[index]);
      },
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getStatusColor(voucher.status),
                      child: Text(
                        voucher.patientName[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          voucher.voucherType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    _getStatusText(voucher.status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _getStatusColor(voucher.status),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // 사용 진행률
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용 회기',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  '${voucher.usedSessions} / ${voucher.totalSessions}회',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: voucher.usageRate / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                voucher.usageRate >= 80
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${voucher.usageRate.toStringAsFixed(1)}% 사용',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 16),
            
            // 기간 및 자부담금
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    '기간',
                    '${DateFormat('yyyy-MM-dd').format(voucher.startDate)}\n~ ${DateFormat('yyyy-MM-dd').format(voucher.endDate)}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.payments,
                    '자부담금',
                    NumberFormat('#,###원').format(voucher.copaymentAmount),
                  ),
                ),
              ],
            ),
            
            if (voucher.status == 'ACTIVE') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showVoucherDetail(voucher),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('상세 보기'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return '활성';
      case 'COMPLETED':
        return '완료';
      case 'EXPIRED':
        return '만료';
      default:
        return status;
    }
  }

  void _showVoucherDetail(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${voucher.patientName} - 바우처 상세'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('바우처 유형', voucher.voucherType),
              _buildDetailRow('총 회기 수', '${voucher.totalSessions}회'),
              _buildDetailRow('사용 회기', '${voucher.usedSessions}회'),
              _buildDetailRow('남은 회기', '${voucher.remainingSessions}회'),
              _buildDetailRow(
                '시작일',
                DateFormat('yyyy-MM-dd').format(voucher.startDate),
              ),
              _buildDetailRow(
                '종료일',
                DateFormat('yyyy-MM-dd').format(voucher.endDate),
              ),
              _buildDetailRow(
                '자부담금',
                NumberFormat('#,###원').format(voucher.copaymentAmount),
              ),
              _buildDetailRow('상태', _getStatusText(voucher.status)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVoucherDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('바우처 등록'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('바우처 등록 기능은 Firebase 연동 후 사용 가능합니다.'),
            SizedBox(height: 8),
            Text(
              '현재는 Mock 데이터로 표시되고 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
