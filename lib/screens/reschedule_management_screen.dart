// 보강·이월·이용권 통합 관리 화면
// T-SCH-UX-01: 바우처 관리를 보강/이월 관리로 통합

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/makeup_ticket.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

class RescheduleManagementScreen extends StatefulWidget {
  const RescheduleManagementScreen({super.key});

  @override
  State<RescheduleManagementScreen> createState() => _RescheduleManagementScreenState();
}

class _RescheduleManagementScreenState extends State<RescheduleManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 보강/이월 데이터
  List<MakeupTicket> _makeupTickets = [];
  bool _isLoadingMakeup = true;
  
  // 이용권 데이터
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoadingVouchers = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadMakeupTickets(),
      _loadVouchers(),
    ]);
  }
  
  Future<void> _loadMakeupTickets() async {
    setState(() => _isLoadingMakeup = true);
    
    try {
      final snapshot = await _firestore
          .collection('makeup_tickets')
          .orderBy('created_at', descending: true)
          .get();
      
      setState(() {
        _makeupTickets = snapshot.docs.map((doc) {
          final data = doc.data();
          return MakeupTicket.fromFirestore(data, doc.id);
        }).toList();
        _isLoadingMakeup = false;
      });
    } catch (e) {
      setState(() => _isLoadingMakeup = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('보강권 데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }
  
  Future<void> _loadVouchers() async {
    setState(() => _isLoadingVouchers = true);
    
    try {
      final snapshot = await _firestore
          .collection('vouchers')
          .orderBy('created_at', descending: true)
          .get();
      
      setState(() {
        _vouchers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoadingVouchers = false;
      });
    } catch (e) {
      setState(() => _isLoadingVouchers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이용권 데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보강·이월·이용권 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '보강/이월'),
            Tab(text: '이용권'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMakeupTab(),
          _buildVoucherTab(),
        ],
      ),
    );
  }
  
  // 보강/이월 탭
  Widget _buildMakeupTab() {
    if (_isLoadingMakeup) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadMakeupTickets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 취소 내역 섹션 (모든 보강권)
          _buildSectionHeader('보강권 목록'),
          const SizedBox(height: 12),
          if (_makeupTickets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('보강권이 없습니다'),
              ),
            )
          else
            ..._makeupTickets.map((ticket) => _buildMakeupCard(ticket)).toList(),
        ],
      ),
    );
  }
  
  // 이용권 탭
  Widget _buildVoucherTab() {
    if (_isLoadingVouchers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadVouchers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 잔여 회차 섹션
          _buildSectionHeader('잔여 회차'),
          const SizedBox(height: 12),
          ..._vouchers
              .where((voucher) => (voucher['remaining_sessions'] ?? 0) > 0)
              .map((voucher) => _buildVoucherCard(voucher))
              .toList(),
          
          const SizedBox(height: 24),
          
          // 사용 내역 섹션
          _buildSectionHeader('사용 내역'),
          const SizedBox(height: 12),
          ..._vouchers
              .where((voucher) => (voucher['used_sessions'] ?? 0) > 0)
              .map((voucher) => _buildVoucherCard(voucher))
              .toList(),
          
          const SizedBox(height: 24),
          
          // 만료 예정 섹션
          _buildSectionHeader('만료 예정'),
          const SizedBox(height: 12),
          ..._vouchers
              .where((voucher) {
                final expiryDate = (voucher['expiry_date'] as Timestamp?)?.toDate();
                if (expiryDate == null) return false;
                final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
                return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
              })
              .map((voucher) => _buildVoucherCard(voucher))
              .toList(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }
  
  Widget _buildMakeupCard(MakeupTicket ticket) {
    Color statusColor;
    String statusText;
    
    switch (ticket.status) {
      case MakeupTicketStatus.available:
        statusColor = Colors.green;
        statusText = '사용 가능';
        break;
      case MakeupTicketStatus.used:
        statusColor = Colors.grey;
        statusText = '사용됨';
        break;
      case MakeupTicketStatus.expired:
        statusColor = Colors.red;
        statusText = '만료';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '알 수 없음';
        break;
    }
    
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
                Expanded(
                  child: Text(
                    ticket.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '원래 예약일: ${DateFormat('yyyy.MM.dd').format(ticket.originalDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (ticket.expiryDate != null)
              Text(
                '만료일: ${DateFormat('yyyy.MM.dd').format(ticket.expiryDate!)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            if (ticket.notes != null && ticket.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '메모: ${ticket.notes!}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final remainingSessions = voucher['remaining_sessions'] ?? 0;
    final totalSessions = voucher['total_sessions'] ?? 0;
    final usedSessions = totalSessions - remainingSessions;
    final expiryDate = (voucher['expiry_date'] as Timestamp?)?.toDate();
    
    final daysUntilExpiry = expiryDate?.difference(DateTime.now()).inDays ?? 0;
    final isExpiringSoon = daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isExpiringSoon ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    voucher['patient_name'] ?? '환자명',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '잔여 $remainingSessions회',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalSessions > 0 ? usedSessions / totalSessions : 0,
              backgroundColor: Colors.grey[200],
              color: AppTheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              '사용: $usedSessions회 / 전체: $totalSessions회',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (expiryDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isExpiringSoon ? Icons.warning : Icons.calendar_today,
                    size: 16,
                    color: isExpiringSoon ? Colors.orange : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '만료일: ${DateFormat('yyyy.MM.dd').format(expiryDate)} (D-$daysUntilExpiry)',
                    style: TextStyle(
                      fontSize: 14,
                      color: isExpiringSoon ? Colors.orange : Colors.grey[600],
                      fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
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
}
