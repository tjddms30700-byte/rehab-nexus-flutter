// 보호자 정기 리포트 작성 화면
// 치료사용 리포트 작성 인터페이스

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/guardian_report.dart';
import '../models/patient.dart';
import '../models/user.dart';

class GuardianReportCreateScreen extends StatefulWidget {
  final String? reportId;      // 수정 시 리포트 ID
  final String? patientId;     // 신규 작성 시 환자 ID
  final AppUser therapist;     // 작성자 (치료사)
  
  const GuardianReportCreateScreen({
    super.key,
    this.reportId,
    this.patientId,
    required this.therapist,
  });
  
  @override
  State<GuardianReportCreateScreen> createState() => _GuardianReportCreateScreenState();
}

class _GuardianReportCreateScreenState extends State<GuardianReportCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _isSaving = false;
  Patient? _selectedPatient;
  GuardianReport? _existingReport;
  
  // 폼 컨트롤러들
  final _periodStartController = TextEditingController();
  final _periodEndController = TextEditingController();
  final _totalSessionsController = TextEditingController();
  final _attendedSessionsController = TextEditingController();
  final _goalsProgressController = TextEditingController();
  final _progressSummaryController = TextEditingController();
  final _comprehensiveOpinionController = TextEditingController();
  final _nextPlanController = TextEditingController();
  final _messageToGuardianController = TextEditingController();
  
  List<String> _mainGoals = [];
  List<DevelopmentChange> _developmentChanges = [];
  List<TherapyActivity> _mainActivities = [];
  List<Assessment> _assessments = [];
  List<HomeProgram> _homePrograms = [];
  List<String> _nextGoals = [];
  
  DateTime? _periodStart;
  DateTime? _periodEnd;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.reportId != null) {
        // 기존 리포트 수정
        final reportDoc = await _firestore.collection('guardian_reports').doc(widget.reportId).get();
        if (reportDoc.exists) {
          _existingReport = GuardianReport.fromFirestore(reportDoc.data()!, reportDoc.id);
          _populateFormWithReport(_existingReport!);
        }
      } else if (widget.patientId != null) {
        // 신규 리포트 작성
        final patientDoc = await _firestore.collection('patients').doc(widget.patientId).get();
        if (patientDoc.exists) {
          _selectedPatient = Patient.fromFirestore(patientDoc.data()!, patientDoc.id);
          _initializeNewReport();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _populateFormWithReport(GuardianReport report) {
    _periodStart = report.periodStart;
    _periodEnd = report.periodEnd;
    _periodStartController.text = DateFormat('yyyy-MM-dd').format(report.periodStart);
    _periodEndController.text = DateFormat('yyyy-MM-dd').format(report.periodEnd);
    _totalSessionsController.text = report.totalSessions.toString();
    _attendedSessionsController.text = report.attendedSessions.toString();
    _goalsProgressController.text = report.goalsProgress;
    _progressSummaryController.text = report.progressSummary;
    _comprehensiveOpinionController.text = report.comprehensiveOpinion;
    _nextPlanController.text = report.nextPlan;
    _messageToGuardianController.text = report.messageToGuardian;
    
    setState(() {
      _mainGoals = List.from(report.mainGoals);
      _developmentChanges = List.from(report.developmentChanges);
      _mainActivities = List.from(report.mainActivities);
      _assessments = List.from(report.assessments);
      _homePrograms = List.from(report.homePrograms);
      _nextGoals = List.from(report.nextGoals);
    });
  }
  
  void _initializeNewReport() {
    // 기본 기간 설정: 지난 달
    final now = DateTime.now();
    _periodEnd = DateTime(now.year, now.month, 0);
    _periodStart = DateTime(_periodEnd!.year, _periodEnd!.month, 1);
    
    _periodStartController.text = DateFormat('yyyy-MM-dd').format(_periodStart!);
    _periodEndController.text = DateFormat('yyyy-MM-dd').format(_periodEnd!);
  }
  
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_periodStart ?? DateTime.now()) : (_periodEnd ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
          _periodStartController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _periodEnd = picked;
          _periodEndController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }
  
  Future<void> _saveReport(ReportStatus status) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedPatient == null && _existingReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 정보가 없습니다.')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final patient = _selectedPatient;
      final patientId = patient?.id ?? _existingReport!.patientId;
      final patientName = patient?.name ?? _existingReport!.patientName;
      final birthDate = patient?.birthDate ?? _existingReport!.birthDate;
      final guardianId = patient != null && patient.guardianIds.isNotEmpty 
          ? patient.guardianIds.first 
          : _existingReport!.guardianId;
      
      final totalSessions = int.tryParse(_totalSessionsController.text) ?? 0;
      final attendedSessions = int.tryParse(_attendedSessionsController.text) ?? 0;
      final attendanceRate = totalSessions > 0 ? (attendedSessions / totalSessions * 100) : 0.0;
      
      final report = GuardianReport(
        id: widget.reportId ?? '',
        patientId: patientId,
        patientName: patientName,
        birthDate: birthDate,
        guardianId: guardianId,
        therapistId: widget.therapist.id,
        therapistName: widget.therapist.name,
        centerName: '위례아쿠수중운동센터', // TODO: 센터 정보 동적 로드
        periodStart: _periodStart!,
        periodEnd: _periodEnd!,
        totalSessions: totalSessions,
        attendedSessions: attendedSessions,
        attendanceRate: attendanceRate,
        mainGoals: _mainGoals,
        goalsProgress: _goalsProgressController.text,
        progressSummary: _progressSummaryController.text,
        developmentChanges: _developmentChanges,
        mainActivities: _mainActivities,
        assessments: _assessments,
        comprehensiveOpinion: _comprehensiveOpinionController.text,
        homePrograms: _homePrograms,
        nextPlan: _nextPlanController.text,
        nextGoals: _nextGoals,
        messageToGuardian: _messageToGuardianController.text,
        status: status,
        createdAt: _existingReport?.createdAt ?? DateTime.now(),
        completedAt: status == ReportStatus.completed ? DateTime.now() : null,
        version: (_existingReport?.version ?? 0) + 1,
        history: [
          ...(_existingReport?.history ?? []),
          ReportHistory(
            modifiedAt: DateTime.now(),
            modifiedBy: widget.therapist.id,
            modifiedByName: widget.therapist.name,
            changeDescription: widget.reportId == null ? '최초 작성' : '수정',
            version: (_existingReport?.version ?? 0) + 1,
          ),
        ],
      );
      
      if (widget.reportId != null) {
        await _firestore.collection('guardian_reports').doc(widget.reportId).update(report.toFirestore());
      } else {
        await _firestore.collection('guardian_reports').add(report.toFirestore());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리포트가 저장되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportId == null ? '리포트 작성' : '리포트 수정'),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: () => _saveReport(ReportStatus.draft),
              child: const Text('임시저장', style: TextStyle(color: Colors.white)),
            ),
          if (!_isSaving)
            TextButton(
              onPressed: () => _saveReport(ReportStatus.completed),
              child: const Text('완료', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 환자 정보 카드
          _buildPatientInfoCard(),
          const SizedBox(height: 16),
          
          // 리포트 기간
          _buildPeriodSection(),
          const SizedBox(height: 16),
          
          // 1. 치료 회기 요약
          _buildSessionSummarySection(),
          const SizedBox(height: 16),
          
          // 2. 주요 치료 목표
          _buildMainGoalsSection(),
          const SizedBox(height: 16),
          
          // 3. 치료 경과 및 발달 변화
          _buildProgressSection(),
          const SizedBox(height: 16),
          
          // 4. 주요 활동 및 개입 방법
          _buildActivitiesSection(),
          const SizedBox(height: 16),
          
          // 5. 측정 결과 및 평가
          _buildAssessmentsSection(),
          const SizedBox(height: 16),
          
          // 6. 종합 소견
          _buildOpinionSection(),
          const SizedBox(height: 16),
          
          // 7. 가정 연계 활동
          _buildHomeProgramsSection(),
          const SizedBox(height: 16),
          
          // 8. 다음 치료 계획
          _buildNextPlanSection(),
          const SizedBox(height: 16),
          
          // 9. 보호자 전달 메시지
          _buildMessageSection(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildPatientInfoCard() {
    final patient = _selectedPatient;
    final report = _existingReport;
    
    if (patient == null && report == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('환자 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('이름: ${patient?.name ?? report!.patientName}'),
            Text('생년월일: ${DateFormat('yyyy-MM-dd').format(patient?.birthDate ?? report!.birthDate)}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('리포트 기간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _periodStartController,
                    decoration: const InputDecoration(
                      labelText: '시작일',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, true),
                    validator: (value) => value!.isEmpty ? '시작일을 선택하세요' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _periodEndController,
                    decoration: const InputDecoration(
                      labelText: '종료일',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, false),
                    validator: (value) => value!.isEmpty ? '종료일을 선택하세요' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. 치료 회기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalSessionsController,
                    decoration: const InputDecoration(labelText: '총 회기 수'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? '필수 입력' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _attendedSessionsController,
                    decoration: const InputDecoration(labelText: '참석 회기 수'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? '필수 입력' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainGoalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('2. 주요 치료 목표', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddGoalDialog(),
                ),
              ],
            ),
            if (_mainGoals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('목표를 추가하세요', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._mainGoals.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;
                return ListTile(
                  leading: Text('${index + 1}.'),
                  title: Text(goal),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _mainGoals.removeAt(index));
                    },
                  ),
                );
              }),
            const SizedBox(height: 8),
            TextFormField(
              controller: _goalsProgressController,
              decoration: const InputDecoration(labelText: '목표 달성 진척도 요약'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3. 치료 경과 및 발달 변화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _progressSummaryController,
              decoration: const InputDecoration(labelText: '전반적 경과 요약'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('발달 변화 항목', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddDevelopmentChangeDialog(),
                ),
              ],
            ),
            if (_developmentChanges.isEmpty)
              const Text('발달 변화 항목을 추가하세요', style: TextStyle(color: Colors.grey))
            else
              ..._developmentChanges.map((change) => ListTile(
                    title: Text(change.category),
                    subtitle: Text(change.description),
                    trailing: Chip(label: Text(change.level)),
                  )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivitiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('4. 주요 활동 및 개입 방법', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddActivityDialog(),
                ),
              ],
            ),
            if (_mainActivities.isEmpty)
              const Text('활동을 추가하세요', style: TextStyle(color: Colors.grey))
            else
              ..._mainActivities.map((activity) => ExpansionTile(
                    title: Text(activity.activityName),
                    children: [
                      ListTile(title: Text('목적: ${activity.purpose}')),
                      ListTile(title: Text('방법: ${activity.method}')),
                      ListTile(title: Text('결과: ${activity.result}')),
                    ],
                  )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAssessmentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('5. 측정 결과 및 평가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddAssessmentDialog(),
                ),
              ],
            ),
            if (_assessments.isEmpty)
              const Text('평가를 추가하세요', style: TextStyle(color: Colors.grey))
            else
              ..._assessments.map((assessment) => ListTile(
                    title: Text(assessment.assessmentName),
                    subtitle: Text('${assessment.score}\n${assessment.description}'),
                    trailing: Text(DateFormat('yyyy-MM-dd').format(assessment.assessmentDate)),
                  )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOpinionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('6. 종합 소견', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _comprehensiveOpinionController,
              decoration: const InputDecoration(
                labelText: '치료사 종합 소견',
                hintText: '전반적인 치료 진행 상황과 아동의 발달 상태에 대한 종합 의견을 작성하세요.',
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHomeProgramsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('7. 가정 연계 활동', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddHomeProgramDialog(),
                ),
              ],
            ),
            if (_homePrograms.isEmpty)
              const Text('가정 연계 활동을 추가하세요', style: TextStyle(color: Colors.grey))
            else
              ..._homePrograms.map((program) => ExpansionTile(
                    title: Text(program.programName),
                    subtitle: Text(program.frequency),
                    children: [
                      ListTile(title: Text('설명: ${program.description}')),
                      ListTile(title: Text('주의사항: ${program.caution}')),
                    ],
                  )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNextPlanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('8. 다음 치료 계획', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nextPlanController,
              decoration: const InputDecoration(labelText: '다음 기간 치료 계획'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('다음 기간 목표', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddNextGoalDialog(),
                ),
              ],
            ),
            if (_nextGoals.isEmpty)
              const Text('다음 목표를 추가하세요', style: TextStyle(color: Colors.grey))
            else
              ..._nextGoals.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;
                return ListTile(
                  leading: Text('${index + 1}.'),
                  title: Text(goal),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _nextGoals.removeAt(index));
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('9. 보호자 전달 메시지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageToGuardianController,
              decoration: const InputDecoration(
                labelText: '보호자 전달 메시지',
                hintText: '보호자님께 전달하고 싶은 메시지를 작성하세요.',
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
  
  // 다이얼로그들
  void _showAddGoalDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '목표 내용'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _mainGoals.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  void _showAddDevelopmentChangeDialog() {
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedLevel = '개선';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('발달 변화 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: '카테고리 (예: 신체 발달)'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '변화 설명'),
              maxLines: 2,
            ),
            DropdownButton<String>(
              value: selectedLevel,
              items: ['개선', '유지', '약화'].map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) => selectedLevel = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                setState(() {
                  _developmentChanges.add(DevelopmentChange(
                    category: categoryController.text,
                    description: descriptionController.text,
                    level: selectedLevel,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  void _showAddActivityDialog() {
    final nameController = TextEditingController();
    final purposeController = TextEditingController();
    final methodController = TextEditingController();
    final resultController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('활동 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '활동명')),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: '목적'), maxLines: 2),
              TextField(controller: methodController, decoration: const InputDecoration(labelText: '방법'), maxLines: 2),
              TextField(controller: resultController, decoration: const InputDecoration(labelText: '결과'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _mainActivities.add(TherapyActivity(
                    activityName: nameController.text,
                    purpose: purposeController.text,
                    method: methodController.text,
                    result: resultController.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  void _showAddAssessmentDialog() {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('평가 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '평가명')),
            TextField(controller: scoreController, decoration: const InputDecoration(labelText: '점수/결과')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '설명'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _assessments.add(Assessment(
                    assessmentName: nameController.text,
                    score: scoreController.text,
                    description: descriptionController.text,
                    assessmentDate: selectedDate,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  void _showAddHomeProgramDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final frequencyController = TextEditingController();
    final cautionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가정 연계 활동 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '프로그램명')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '설명'), maxLines: 2),
              TextField(controller: frequencyController, decoration: const InputDecoration(labelText: '빈도 (예: 주 3회, 각 10분)')),
              TextField(controller: cautionController, decoration: const InputDecoration(labelText: '주의사항'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _homePrograms.add(HomeProgram(
                    programName: nameController.text,
                    description: descriptionController.text,
                    frequency: frequencyController.text,
                    caution: cautionController.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  void _showAddNextGoalDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다음 목표 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '목표 내용'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _nextGoals.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _periodStartController.dispose();
    _periodEndController.dispose();
    _totalSessionsController.dispose();
    _attendedSessionsController.dispose();
    _goalsProgressController.dispose();
    _progressSummaryController.dispose();
    _comprehensiveOpinionController.dispose();
    _nextPlanController.dispose();
    _messageToGuardianController.dispose();
    super.dispose();
  }
}
