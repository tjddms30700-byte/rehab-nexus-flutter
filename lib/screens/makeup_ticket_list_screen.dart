import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Map<String, bool> _isPendingMap = {}; // 보강권별 pending 상태 저장
  bool _isLoading = false;
  String _filterStatus = 'ALL'; // ALL, AVAILABLE, USED, EXPIRED

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firestore에서 보강권 데이터 조회
      Query query = FirebaseFirestore.instance.collection('makeup_tickets');
      
      // 필터 적용
      if (_filterStatus != 'ALL') {
        query = query.where('status', isEqualTo: _filterStatus.toLowerCase());
      }
      
      final snapshot = await query.orderBy('created_at', descending: true).get();
      
      _tickets = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // pending 상태 저장
        final status = data['status'] as String?;
        _isPendingMap[doc.id] = (status == 'pending');
        
        return MakeupTicket(
          id: doc.id,
          patientId: data['patient_id'] ?? '',
          patientName: data['patient_name'] ?? '',
          originalAttendanceId: data['original_attendance_id'] ?? '',
          originalDate: (data['original_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          originalTimeSlot: data['original_time_slot'] ?? '',
          status: _parseStatus(status),
          expiryDate: (data['expiry_date'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
          therapistId: data['therapist_id'] ?? '',
          therapistName: data['therapist_name'] ?? '',
          notes: data['notes'],
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          usedDate: (data['used_date'] as Timestamp?)?.toDate(),
        );
      }).toList();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  MakeupTicketStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return MakeupTicketStatus.available;
      case 'approved':
        return MakeupTicketStatus.available;
      case 'used':
        return MakeupTicketStatus.used;
      case 'expired':
        return MakeupTicketStatus.expired;
      case 'cancelled':
        return MakeupTicketStatus.expired;
      default:
        return MakeupTicketStatus.available;
    }
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
            // Pending 상태: 승인/거절 버튼
            if (_isPendingMap[ticket.id] == true) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectMakeupTicket(ticket),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('거절'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveMakeupTicket(ticket),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            // Available 상태: 사용하기 버튼
            if (ticket.status == MakeupTicketStatus.available && _isPendingMap[ticket.id] != true) ...[
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

  
  Future<void> _approveMakeupTicket(MakeupTicket ticket) async {
    try {
      await FirebaseFirestore.instance
          .collection('makeup_tickets')
          .doc(ticket.id)
          .update({
        'status': 'approved',
        'approved_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ticket.patientName}의 보강권이 승인되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTickets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e')),
        );
      }
    }
  }
  
  Future<void> _rejectMakeupTicket(MakeupTicket ticket) async {
    // 거절 사유 입력 다이얼로그
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보강권 거절'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${ticket.patientName}의 보강권을 거절하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '거절 사유 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('makeup_tickets')
            .doc(ticket.id)
            .update({
          'status': 'cancelled',
          'rejection_reason': reasonController.text.trim(),
          'rejected_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${ticket.patientName}의 보강권이 거절되었습니다'),
              backgroundColor: Colors.red,
            ),
          );
          _loadTickets();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('거절 실패: $e')),
          );
        }
      }
    }
    
    reasonController.dispose();
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
