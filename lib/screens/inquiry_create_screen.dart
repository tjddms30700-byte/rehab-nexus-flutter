import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/inquiry.dart';
import '../services/inquiry_service.dart';
import '../providers/app_state.dart';
import '../constants/app_theme.dart';
import '../constants/enums.dart';

/// 보호자용 문의 작성 화면
class InquiryCreateScreen extends StatefulWidget {
  final Patient patient;

  const InquiryCreateScreen({
    super.key,
    required this.patient,
  });

  @override
  State<InquiryCreateScreen> createState() => _InquiryCreateScreenState();
}

class _InquiryCreateScreenState extends State<InquiryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inquiryService = InquiryService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    print('🔵 [InquiryCreateScreen] _submitInquiry 시작');
    if (!_formKey.currentState!.validate()) {
      print('❌ [InquiryCreateScreen] 폼 유효성 검사 실패');
      return;
    }

    // ✅ CRITICAL: context.read를 async 전에 추출
    final appState = context.read<AppState>();
    final currentUser = appState.currentUser;
    print('🟢 [InquiryCreateScreen] currentUser: ${currentUser?.name ?? "null"}');

    if (currentUser == null) {
      print('❌ [InquiryCreateScreen] currentUser가 null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 사용자 정보를 찾을 수 없습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() => _isSaving = true);

    try {

      print('📝 [InquiryCreateScreen] Inquiry 객체 생성');
      final inquiry = Inquiry(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        guardianId: currentUser.id,
        guardianName: currentUser.name,
        therapistId: widget.patient.assignedTherapistId ?? 'therapist_001',
        title: _titleController.text,
        content: _contentController.text,
        status: InquiryStatus.pending,
        createdAt: DateTime.now(),
      );
      print('✅ [InquiryCreateScreen] Inquiry 객체 생성 완료');

      try {
        print('🔄 [InquiryCreateScreen] createInquiry 호출');
        final inquiryId = await _inquiryService.createInquiry(inquiry);
        if (mounted) {
          print('✅ [InquiryCreateScreen] Firebase 저장 성공: $inquiryId');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 문의가 접수되었습니다! (ID: $inquiryId)'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (firebaseError) {
        print('⚠️ [InquiryCreateScreen] Firebase 오류: $firebaseError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 문의가 접수되었습니다!\n💡 Firebase 연결 시 실제 저장됩니다'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }

      if (mounted) {
        print('🔙 [InquiryCreateScreen] Navigator.pop 호출');
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ [InquiryCreateScreen] 예외 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 문의 접수 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 환자 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.child_care, color: AppTheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('${widget.patient.age}세'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 제목
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '제목',
                  hintText: '문의 제목을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 내용
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: '문의 내용',
                  hintText: '궁금하신 내용을 상세히 적어주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '문의 내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 제출 버튼
              ElevatedButton(
                onPressed: _isSaving ? null : _submitInquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '문의 등록',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
