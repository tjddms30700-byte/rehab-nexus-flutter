import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/makeup_ticket.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

/// 보강권 조회 화면
class MakeupTicketListScreen extends StatefulWidget {
  const MakeupTicketListScreen({super.key});

  @override
  State<MakeupTicketListScreen> createState() => _MakeupTicketListScreenState();
}

class _MakeupTicketListScreenState extends State<MakeupTicketListScreen> {
  List<MakeupTicket> _tickets = [];
  bool _isLoading = false;
  String _filterStatus = 'ALL'; // ALL, AVAILABLE, USED, EXPIRED

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    setState(() {
      _isLoading = true;
    });

    // Mock 데이터 생성
    final now = DateTime.now();
    _tickets = [
      MakeupTicket(
        id: 'makeup_001',
        patientId: 'patient_001',
        patientName: '홍길동',
        originalAttendanceId: 'att_001',
        originalDate: now.subtract(const Duration(days: 7)),
        originalTimeSlot: '10:00-11:00',
        status: MakeupTicketStatus.available,
        expiryDate: now.add(const Duration(days: 23)),
        therapistId: 'therapist_001',
        therapistName: '김치료',
        notes: '독감으로 인한 결석',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      MakeupTicket(
        id: 'makeup_002',
        patientId: 'patient_002',
        patientName: '김영희',
        originalAttendanceId: 'att_002',
        originalDate: now.subtract(const Duration(days: 15)),
        originalTimeSlot: '14:00-15:00',
        status: MakeupTicketStatus.used,
        expiryDate: now.add(const Duration(days: 15)),
        therapistId: 'therapist_001',
        therapistName: '김치료',
        notes: '가족 행사로 결석',
        usedDate: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      MakeupTicket(
        id: 'makeup_003',
        patientId: 'patient_003',
        patientName: '이철수',
        originalAttendanceId: 'att_003',
        originalDate: now.subtract(const Duration(days: 35)),
        originalTimeSlot: '16:00-17:00',
        status: MakeupTicketStatus.expired,
        expiryDate: now.subtract(const Duration(days: 5)),
        therapistId: 'therapist_001',
        therapistName: '김치료',
        notes: '급한 일정으로 결석',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  List<MakeupTicket> get _filteredTickets {
    if (_filterStatus == 'ALL') return _tickets;
    
    switch (_filterStatus) {
      case 'AVAILABLE':
        return _tickets.where((t) => t.status == MakeupTicketStatus.available).toList();
      case 'USED':
        return _tickets.where((t) => t.status == MakeupTicketStatus.used).toList();
      case 'EXPIRED':
        return _tickets.where((t) => t.status == MakeupTicketStatus.expired).toList();
      default:
        return _tickets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보강권 조회'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSummary(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                    ? _buildEmptyState()
                    : _buildTicketList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final available = _tickets.where((t) => t.status == MakeupTicketStatus.available).length;
    final used = _tickets.where((t) => t.status == MakeupTicketStatus.used).length;
    final expired = _tickets.where((t) => t.status == MakeupTicketStatus.expired).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('사용 가능', '$available', Colors.green),
          _buildSummaryItem('사용 완료', '$used', Colors.blue),
          _buildSummaryItem('만료', '$expired', Colors.red),
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
          _buildFilterChip('사용 가능', 'AVAILABLE'),
          const SizedBox(width: 8),
          _buildFilterChip('사용 완료', 'USED'),
          const SizedBox(width: 8),
          _buildFilterChip('만료', 'EXPIRED'),
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
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '보강권이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTickets.length,
      itemBuilder: (context, index) {
        return _buildTicketCard(_filteredTickets[index]);
      },
    );
  }

  Widget _buildTicketCard(MakeupTicket ticket) {
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
                      backgroundColor: _getStatusColor(ticket.status),
                      child: Text(
                        ticket.patientName[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '발급: ${DateFormat('yyyy-MM-dd').format(ticket.createdAt)}',
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
                    _getStatusText(ticket.status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _getStatusColor(ticket.status),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.event_busy, '결석 일시',
                '${DateFormat('yyyy-MM-dd').format(ticket.originalDate)} ${ticket.originalTimeSlot}'),
            const SizedBox(height: 8),
            if (ticket.status == MakeupTicketStatus.used && ticket.usedDate != null)
              _buildInfoRow(Icons.event_available, '사용 일시',
                  DateFormat('yyyy-MM-dd HH:mm').format(ticket.usedDate!)),
            if (ticket.status == MakeupTicketStatus.used && ticket.usedDate != null)
              const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              '만료일',
              DateFormat('yyyy-MM-dd').format(ticket.expiryDate),
              isExpiring: ticket.status == MakeupTicketStatus.available &&
                  ticket.expiryDate.difference(DateTime.now()).inDays <= 7,
            ),
            if (ticket.notes != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.notes, '사유', ticket.notes!),
            ],
            if (ticket.status == MakeupTicketStatus.available) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showUseTicketDialog(ticket),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('사용하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isExpiring = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isExpiring ? Colors.red : Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isExpiring ? Colors.red : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(MakeupTicketStatus status) {
    switch (status) {
      case MakeupTicketStatus.available:
        return Colors.green;
      case MakeupTicketStatus.used:
        return Colors.blue;
      case MakeupTicketStatus.expired:
        return Colors.red;
    }
  }

  String _getStatusText(MakeupTicketStatus status) {
    switch (status) {
      case MakeupTicketStatus.available:
        return '사용 가능';
      case MakeupTicketStatus.used:
        return '사용 완료';
      case MakeupTicketStatus.expired:
        return '만료';
    }
  }

  void _showUseTicketDialog(MakeupTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보강권 사용'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ticket.patientName}님의 보강권을 사용하시겠습니까?'),
            const SizedBox(height: 16),
            Text(
              '원 결석 일시: ${DateFormat('yyyy-MM-dd').format(ticket.originalDate)} ${ticket.originalTimeSlot}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useTicket(ticket);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('사용하기'),
          ),
        ],
      ),
    );
  }

  void _useTicket(MakeupTicket ticket) {
    setState(() {
      final index = _tickets.indexWhere((t) => t.id == ticket.id);
      if (index != -1) {
        _tickets[index] = ticket.copyWith(
          status: MakeupTicketStatus.used,
          usedDate: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${ticket.patientName}님의 보강권이 사용되었습니다'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
