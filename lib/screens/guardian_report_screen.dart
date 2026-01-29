// 보호자용 치료 리포트 조회 화면
// 리포트 목록 조회 및 상세 보기

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/guardian_report.dart';
import '../models/user.dart';
import '../models/patient.dart';
import '../constants/user_roles.dart';
import 'guardian_report_create_screen.dart';

class GuardianReportScreen extends StatefulWidget {
  final AppUser user;           // 현재 사용자
  final String? patientId;      // 특정 환자의 리포트 조회 (선택사항)
  
  const GuardianReportScreen({
    super.key,
    required this.user,
    this.patientId,
  });
  
  @override
  State<GuardianReportScreen> createState() => _GuardianReportScreenState();
}

class _GuardianReportScreenState extends State<GuardianReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<GuardianReport> _reports = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, draft, completed, sent
  
  @override
  void initState() {
    super.initState();
    _loadReports();
  }
  
  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    try {
      Query query = _firestore.collection('guardian_reports');
      
      // 역할별 필터링
      if (widget.user.role == UserRole.guardian) {
        // 보호자: 자신의 리포트만
        query = query.where('guardian_id', isEqualTo: widget.user.id);
      } else if (widget.user.role == UserRole.therapist) {
        // 치료사: 자신이 작성한 리포트만
        query = query.where('therapist_id', isEqualTo: widget.user.id);
      }
      // 센터장/관리자: 모든 리포트 조회 가능
      
      // 특정 환자 필터
      if (widget.patientId != null) {
        query = query.where('patient_id', isEqualTo: widget.patientId);
      }
      
      // 상태 필터
      if (_selectedFilter != 'all') {
        query = query.where('status', isEqualTo: _selectedFilter);
      }
      
      final querySnapshot = await query
          .orderBy('created_at', descending: true)
          .get();
      
      setState(() {
        _reports = querySnapshot.docs
            .map((doc) => GuardianReport.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리포트 로드 실패: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('치료 리포트'),
        actions: [
          // 치료사만 리포트 작성 가능
          if (widget.user.role == UserRole.therapist || widget.user.role == UserRole.centerAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showPatientSelectionDialog(),
              tooltip: '새 리포트 작성',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
              _loadReports();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('전체')),
              const PopupMenuItem(value: 'draft', child: Text('작성 중')),
              const PopupMenuItem(value: 'completed', child: Text('작성 완료')),
              const PopupMenuItem(value: 'sent', child: Text('발송됨')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(_reports[index]);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '리포트가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (widget.user.role == UserRole.therapist || widget.user.role == UserRole.centerAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showPatientSelectionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('리포트 작성하기'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard(GuardianReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showReportDetail(report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 환자명 + 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '생년월일: ${DateFormat('yyyy-MM-dd').format(report.birthDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(report.status),
                ],
              ),
              const Divider(height: 24),
              
              // 리포트 기간
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(report.periodStart)} ~ ${DateFormat('yyyy.MM.dd').format(report.periodEnd)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 치료사 정보
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '담당 치료사: ${report.therapistName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 회기 정보
              Row(
                children: [
                  const Icon(Icons.event_note, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '총 ${report.totalSessions}회기 / 참석 ${report.attendedSessions}회기 (${report.attendanceRate.toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              
              // 작성/발송 일시
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '작성: ${DateFormat('yyyy-MM-dd').format(report.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (report.readAt != null)
                    Text(
                      '읽음: ${DateFormat('yyyy-MM-dd').format(report.readAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              
              // 액션 버튼들
              if (widget.user.role == UserRole.therapist || widget.user.role == UserRole.centerAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editReport(report),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('수정'),
                    ),
                    if (report.status == ReportStatus.draft)
                      TextButton.icon(
                        onPressed: () => _completeReport(report),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('완료'),
                      ),
                    if (report.status == ReportStatus.completed)
                      TextButton.icon(
                        onPressed: () => _sendReport(report),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('발송'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case ReportStatus.draft:
        color = Colors.grey;
        label = '작성 중';
        break;
      case ReportStatus.completed:
        color = Colors.blue;
        label = '작성 완료';
        break;
      case ReportStatus.sent:
        color = Colors.green;
        label = '발송됨';
        break;
      case ReportStatus.read:
        color = Colors.purple;
        label = '읽음';
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
  
  void _showReportDetail(GuardianReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianReportDetailScreen(report: report, user: widget.user),
      ),
    ).then((_) => _loadReports());
  }
  
  void _editReport(GuardianReport report) {
    if (widget.user.role != UserRole.therapist && widget.user.role != UserRole.centerAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('권한이 없습니다.')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianReportCreateScreen(
          reportId: report.id,
          therapist: widget.user,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadReports();
      }
    });
  }
  
  Future<void> _completeReport(GuardianReport report) async {
    try {
      await _firestore.collection('guardian_reports').doc(report.id).update({
        'status': 'completed',
        'completed_at': Timestamp.now(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리포트가 완료되었습니다.')),
      );
      _loadReports();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('완료 처리 실패: $e')),
      );
    }
  }
  
  Future<void> _sendReport(GuardianReport report) async {
    try {
      await _firestore.collection('guardian_reports').doc(report.id).update({
        'status': 'sent',
        'sent_at': Timestamp.now(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리포트가 발송되었습니다.')),
      );
      _loadReports();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('발송 실패: $e')),
      );
    }
  }
  
  void _showPatientSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 선택'),
        content: const Text('리포트를 작성할 환자를 선택하세요.\n(환자 목록 연동 예정)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 환자 선택 후 리포트 작성 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('환자 목록 연동 예정입니다.')),
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 리포트 상세 화면
class GuardianReportDetailScreen extends StatefulWidget {
  final GuardianReport report;
  final AppUser user;
  
  const GuardianReportDetailScreen({
    super.key,
    required this.report,
    required this.user,
  });
  
  @override
  State<GuardianReportDetailScreen> createState() => _GuardianReportDetailScreenState();
}

class _GuardianReportDetailScreenState extends State<GuardianReportDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }
  
  Future<void> _markAsRead() async {
    // 보호자가 읽었을 때만 읽음 처리
    if (widget.user.role == UserRole.guardian && 
        widget.report.status == ReportStatus.sent && 
        widget.report.readAt == null) {
      try {
        await _firestore.collection('guardian_reports').doc(widget.report.id).update({
          'status': 'read',
          'read_at': Timestamp.now(),
        });
      } catch (e) {
        // 읽음 처리 실패는 무시
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리포트 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'PDF 다운로드',
          ),
          if (widget.user.role == UserRole.therapist || widget.user.role == UserRole.centerAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuardianReportCreateScreen(
                      reportId: widget.report.id,
                      therapist: widget.user,
                    ),
                  ),
                );
              },
              tooltip: '수정',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 0. 표지
          _buildCoverSection(),
          const SizedBox(height: 24),
          
          // 1. 치료 회기 요약
          _buildSessionSummarySection(),
          const SizedBox(height: 24),
          
          // 2. 주요 치료 목표
          _buildGoalsSection(),
          const SizedBox(height: 24),
          
          // 3. 치료 경과 및 발달 변화
          _buildProgressSection(),
          const SizedBox(height: 24),
          
          // 4. 주요 활동 및 개입 방법
          _buildActivitiesSection(),
          const SizedBox(height: 24),
          
          // 5. 측정 결과 및 평가
          _buildAssessmentsSection(),
          const SizedBox(height: 24),
          
          // 6. 종합 소견
          _buildOpinionSection(),
          const SizedBox(height: 24),
          
          // 7. 가정 연계 활동
          _buildHomeProgramsSection(),
          const SizedBox(height: 24),
          
          // 8. 다음 치료 계획
          _buildNextPlanSection(),
          const SizedBox(height: 24),
          
          // 9. 보호자 전달 메시지
          _buildMessageSection(),
        ],
      ),
    );
  }
  
  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoverSection() {
    return _buildSectionCard(
      '표지',
      [
        Center(
          child: Column(
            children: [
              const Text(
                'AQU LAB Care',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI 기반 맞춤형 수중재활 보호자 리포트',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildInfoRow('아동명', widget.report.patientName),
              _buildInfoRow('생년월일', DateFormat('yyyy.MM.dd').format(widget.report.birthDate)),
              _buildInfoRow(
                '리포트 기간',
                '${DateFormat('yyyy.MM.dd').format(widget.report.periodStart)} ~ ${DateFormat('yyyy.MM.dd').format(widget.report.periodEnd)}',
              ),
              _buildInfoRow('담당 치료사', widget.report.therapistName),
              _buildInfoRow('센터명', widget.report.centerName),
              const SizedBox(height: 24),
              Text(
                widget.report.footerNotice,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
  
  Widget _buildSessionSummarySection() {
    return _buildSectionCard(
      '1. 치료 회기 요약',
      [
        _buildInfoRow('총 회기 수', '${widget.report.totalSessions}회'),
        _buildInfoRow('참석 회기 수', '${widget.report.attendedSessions}회'),
        _buildInfoRow('출석률', '${widget.report.attendanceRate.toStringAsFixed(1)}%'),
      ],
    );
  }
  
  Widget _buildGoalsSection() {
    return _buildSectionCard(
      '2. 주요 치료 목표',
      [
        ...widget.report.mainGoals.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${entry.key + 1}. ${entry.value}'),
          );
        }),
        if (widget.report.goalsProgress.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('목표 달성 진척도:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.report.goalsProgress),
        ],
      ],
    );
  }
  
  Widget _buildProgressSection() {
    return _buildSectionCard(
      '3. 치료 경과 및 발달 변화',
      [
        if (widget.report.progressSummary.isNotEmpty) ...[
          const Text('전반적 경과:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.report.progressSummary),
          const SizedBox(height: 16),
        ],
        if (widget.report.developmentChanges.isNotEmpty) ...[
          const Text('발달 변화:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...widget.report.developmentChanges.map((change) {
            return Card(
              color: Colors.blue[50],
              child: ListTile(
                title: Text(change.category),
                subtitle: Text(change.description),
                trailing: Chip(
                  label: Text(change.level),
                  backgroundColor: change.level == '개선' ? Colors.green : Colors.orange,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
  
  Widget _buildActivitiesSection() {
    return _buildSectionCard(
      '4. 주요 활동 및 개입 방법',
      [
        ...widget.report.mainActivities.map((activity) {
          return ExpansionTile(
            title: Text(activity.activityName),
            children: [
              ListTile(title: Text('목적: ${activity.purpose}')),
              ListTile(title: Text('방법: ${activity.method}')),
              ListTile(title: Text('결과: ${activity.result}')),
            ],
          );
        }),
      ],
    );
  }
  
  Widget _buildAssessmentsSection() {
    return _buildSectionCard(
      '5. 측정 결과 및 평가',
      [
        ...widget.report.assessments.map((assessment) {
          return Card(
            child: ListTile(
              title: Text(assessment.assessmentName),
              subtitle: Text('${assessment.score}\n${assessment.description}'),
              trailing: Text(DateFormat('yyyy-MM-dd').format(assessment.assessmentDate)),
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildOpinionSection() {
    return _buildSectionCard(
      '6. 종합 소견',
      [
        Text(widget.report.comprehensiveOpinion),
      ],
    );
  }
  
  Widget _buildHomeProgramsSection() {
    return _buildSectionCard(
      '7. 가정 연계 활동 (홈 프로그램)',
      [
        ...widget.report.homePrograms.map((program) {
          return ExpansionTile(
            title: Text(program.programName),
            subtitle: Text('빈도: ${program.frequency}'),
            children: [
              ListTile(title: Text('설명: ${program.description}')),
              ListTile(title: Text('주의사항: ${program.caution}')),
            ],
          );
        }),
      ],
    );
  }
  
  Widget _buildNextPlanSection() {
    return _buildSectionCard(
      '8. 다음 치료 계획',
      [
        Text(widget.report.nextPlan),
        const SizedBox(height: 16),
        const Text('다음 기간 목표:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.report.nextGoals.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${entry.key + 1}. ${entry.value}'),
          );
        }),
      ],
    );
  }
  
  Widget _buildMessageSection() {
    return _buildSectionCard(
      '9. 보호자 전달 메시지',
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.report.messageToGuardian,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  void _downloadPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 PDF 다운로드 기능\n💡 구현 예정입니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
