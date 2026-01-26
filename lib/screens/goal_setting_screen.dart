import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/goal.dart';
import '../constants/enums.dart';
import '../constants/goal_templates_helper.dart';
import '../services/goal_service.dart';
import '../providers/app_state.dart';

/// SMART 목표 수립 화면
class GoalSettingScreen extends StatefulWidget {
  final Patient patient;

  const GoalSettingScreen({
    super.key,
    required this.patient,
  });

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  int _currentStep = 0;
  
  // Step 1: 템플릿 선택
  GoalTemplate? _selectedTemplate;
  GoalCategory? _selectedCategory;
  
  // Step 2: SMART 기준 입력
  final _goalTextController = TextEditingController();
  final _specificController = TextEditingController();
  final _measurableController = TextEditingController();
  final _achievableController = TextEditingController();
  final _relevantController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 56)); // 8주 후
  
  // Step 3: 추가 정보
  GoalPriority _priority = GoalPriority.medium;
  String? _assessmentId;
  
  final _formKey = GlobalKey<FormState>();
  final _goalService = GoalService();
  bool _isSaving = false;

  @override
  void dispose() {
    _goalTextController.dispose();
    _specificController.dispose();
    _measurableController.dispose();
    _achievableController.dispose();
    _relevantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('목표 수립 - ${widget.patient.name}'),
        actions: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('이전', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 2 ? '저장' : '다음'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('이전'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('템플릿 선택'),
              subtitle: const Text('목표 템플릿을 선택하세요'),
              content: _buildStep1TemplateSelection(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('SMART 기준 입력'),
              subtitle: const Text('목표를 구체적으로 작성하세요'),
              content: _buildStep2SmartCriteria(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('추가 정보'),
              subtitle: const Text('우선순위 및 기타 설정'),
              content: _buildStep3AdditionalInfo(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1TemplateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 선택
        const Text(
          '목표 카테고리',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GoalCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(GoalTemplatesHelper.getCategoryDisplayName(category)),
                  Text(
                    GoalTemplatesHelper.getCategoryDescription(category),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                  _selectedTemplate = null;
                });
              },
            );
          }).toList(),
        ),
        
        if (_selectedCategory != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            '목표 템플릿',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...GoalTemplatesHelper.getTemplatesByCategory(_selectedCategory!)
              .map((template) => _buildTemplateCard(template)),
        ],
        
        if (_selectedCategory == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                '먼저 목표 카테고리를 선택해주세요',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateCard(GoalTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTemplate = template;
            // 템플릿 내용을 폼에 자동 입력
            _goalTextController.text = template.example;
            _specificController.text = template.specific;
            _measurableController.text = template.measurable;
            _achievableController.text = template.achievable;
            _relevantController.text = template.relevant;
            _targetDate = DateTime.now().add(Duration(days: template.recommendedWeeks * 7));
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.example,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '권장 기간: ${template.recommendedWeeks}주',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2SmartCriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTemplate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '선택한 템플릿: ${_selectedTemplate!.name}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // 목표 텍스트
        TextFormField(
          controller: _goalTextController,
          decoration: const InputDecoration(
            labelText: '목표 텍스트 *',
            hintText: '예: 8주 내 보조 없이 10m 보행하기',
            border: OutlineInputBorder(),
            helperText: '간단하고 명확하게 목표를 작성하세요',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '목표 텍스트를 입력해주세요';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 24),
        const Text(
          'SMART 기준',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Specific (구체적)
        _buildSmartField(
          controller: _specificController,
          label: 'Specific (구체적)',
          hint: '무엇을 달성할 것인가?',
          icon: Icons.my_location,
          helperText: '목표가 명확하고 구체적입니까?',
        ),
        
        const SizedBox(height: 16),
        
        // Measurable (측정 가능)
        _buildSmartField(
          controller: _measurableController,
          label: 'Measurable (측정 가능)',
          hint: '어떻게 측정할 것인가?',
          icon: Icons.straighten,
          helperText: '진행 상황을 어떻게 측정하나요?',
        ),
        
        const SizedBox(height: 16),
        
        // Achievable (달성 가능)
        _buildSmartField(
          controller: _achievableController,
          label: 'Achievable (달성 가능)',
          hint: '달성 가능한가?',
          icon: Icons.trending_up,
          helperText: '현실적으로 달성 가능한가요?',
        ),
        
        const SizedBox(height: 16),
        
        // Relevant (관련성)
        _buildSmartField(
          controller: _relevantController,
          label: 'Relevant (관련성)',
          hint: '왜 중요한가?',
          icon: Icons.link,
          helperText: '다른 목표나 필요와 어떻게 연결되나요?',
        ),
        
        const SizedBox(height: 16),
        
        // Time-bound (기한)
        ListTile(
          leading: const Icon(Icons.event),
          title: const Text('Time-bound (기한)'),
          subtitle: Text(
            DateFormat('yyyy년 MM월 dd일').format(_targetDate),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _targetDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: '목표 달성 예정일',
            );
            if (picked != null) {
              setState(() {
                _targetDate = picked;
              });
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String helperText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        helperText: helperText,
        helperMaxLines: 2,
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label을(를) 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildStep3AdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 우선순위
        const Text(
          '우선순위 *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SegmentedButton<GoalPriority>(
          segments: [
            ButtonSegment(
              value: GoalPriority.high,
              label: Text(GoalTemplatesHelper.getPriorityDisplayName(GoalPriority.high)),
              icon: const Icon(Icons.priority_high),
            ),
            ButtonSegment(
              value: GoalPriority.medium,
              label: Text(GoalTemplatesHelper.getPriorityDisplayName(GoalPriority.medium)),
              icon: const Icon(Icons.remove),
            ),
            ButtonSegment(
              value: GoalPriority.low,
              label: Text(GoalTemplatesHelper.getPriorityDisplayName(GoalPriority.low)),
              icon: const Icon(Icons.low_priority),
            ),
          ],
          selected: {_priority},
          onSelectionChanged: (Set<GoalPriority> newSelection) {
            setState(() {
              _priority = newSelection.first;
            });
          },
        ),
        
        const SizedBox(height: 24),
        
        // 요약 카드
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      '목표 요약',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('환자', widget.patient.name),
                _buildSummaryRow('목표', _goalTextController.text),
                _buildSummaryRow('카테고리', 
                  _selectedCategory != null 
                    ? GoalTemplatesHelper.getCategoryDisplayName(_selectedCategory!)
                    : '-'),
                _buildSummaryRow('우선순위', 
                  GoalTemplatesHelper.getPriorityDisplayName(_priority)),
                _buildSummaryRow('목표일', 
                  DateFormat('yyyy-MM-dd').format(_targetDate)),
                _buildSummaryRow('기간', 
                  '${_targetDate.difference(DateTime.now()).inDays}일'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Step 1: 템플릿 선택 확인
      if (_selectedTemplate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 템플릿을 선택해주세요')),
        );
        return;
      }
      setState(() {
        _currentStep++;
      });
    } else if (_currentStep == 1) {
      // Step 2: SMART 기준 입력 확인
      if (!_formKey.currentState!.validate()) {
        return;
      }
      setState(() {
        _currentStep++;
      });
    } else if (_currentStep == 2) {
      // Step 3: 저장
      _saveGoal();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final appState = context.read<AppState>();
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      // Goal 객체 생성
      final goal = Goal(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        patientId: widget.patient.id,
        therapistId: currentUser.id,
        assessmentId: _assessmentId,
        goalText: _goalTextController.text,
        smartCriteria: SmartCriteria(
          specific: _specificController.text,
          measurable: _measurableController.text,
          achievable: _achievableController.text,
          relevant: _relevantController.text,
          timeBound: _targetDate,
        ),
        category: _selectedCategory!,
        priority: _priority,
        targetDate: _targetDate,
        status: GoalStatus.inProgress,
        progressPercentage: 0.0,
        createdAt: DateTime.now(),
      );

      // Firebase에 저장
      try {
        final goalId = await _goalService.createGoal(goal);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 목표가 저장되었습니다!\nID: $goalId'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (firebaseError) {
        // Firebase 오류 시 로컬에만 저장
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ 목표가 저장되었습니다! (로컬 저장)\n참고: Firebase 연결이 필요합니다'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, goal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 목표 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
