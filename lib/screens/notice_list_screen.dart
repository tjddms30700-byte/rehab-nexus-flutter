import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notice.dart';
import '../constants/enums.dart';

/// 공지사항 화면
class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({Key? key}) : super(key: key);

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  List<Notice> _notices = [];
  NoticeType _selectedType = NoticeType.center;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    setState(() {
      _isLoading = true;
    });

    // Mock 데이터
    final now = DateTime.now();
    _notices = [
      Notice(
        id: 'notice_001',
        organizationId: 'org_001',
        title: '🔥 긴급: 1월 28일 휴무 안내',
        content: '설비 점검으로 인해 1월 28일은 센터 휴무입니다.\n예약 변경이 필요하신 분은 연락 부탁드립니다.',
        type: NoticeType.center,
        priority: NoticePriority.urgent,
        publishDate: now.subtract(const Duration(hours: 2)),
        isPinned: true,
        viewCount: 24,
        authorId: 'admin_001',
        authorName: '관리자',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Notice(
        id: 'notice_002',
        organizationId: 'org_001',
        title: '📢 2월 치료 일정 안내',
        content:
            '2월 치료 일정이 확정되었습니다.\n1. 2월 1일-5일: 정상 운영\n2. 2월 6일-9일: 설 연휴 휴무\n3. 2월 10일부터 정상 운영',
        type: NoticeType.center,
        priority: NoticePriority.important,
        publishDate: now.subtract(const Duration(days: 1)),
        isPinned: false,
        viewCount: 42,
        authorId: 'admin_001',
        authorName: '관리자',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Notice(
        id: 'notice_003',
        organizationId: 'org_001',
        title: '수중 치료 프로그램 개선 안내',
        content:
            '수중 치료 프로그램이 개선되었습니다.\n- 수온 조절 시스템 업그레이드\n- 새로운 운동 기구 도입\n- 치료 시간 조정 가능',
        type: NoticeType.customer,
        priority: NoticePriority.normal,
        publishDate: now.subtract(const Duration(days: 3)),
        isPinned: false,
        viewCount: 67,
        authorId: 'admin_001',
        authorName: '관리자',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Notice(
        id: 'notice_004',
        organizationId: 'org_001',
        title: '치료비 결제 방법 추가',
        content:
            '간편 결제 서비스가 추가되었습니다.\n- 카카오페이\n- 네이버페이\n- 토스페이\n편리한 결제를 이용해 주세요.',
        type: NoticeType.customer,
        priority: NoticePriority.normal,
        publishDate: now.subtract(const Duration(days: 5)),
        isPinned: false,
        viewCount: 89,
        authorId: 'admin_001',
        authorName: '관리자',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  List<Notice> get _filteredNotices {
    return _notices.where((n) => n.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateNotice,
          ),
        ],
      ),
      body: Column(
        children: [
          // 탭 선택
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    '센터 공지',
                    NoticeType.center,
                    _selectedType == NoticeType.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    '고객 공지',
                    NoticeType.customer,
                    _selectedType == NoticeType.customer,
                  ),
                ),
              ],
            ),
          ),

          // 공지사항 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotices.isEmpty
                    ? Center(
                        child: Text(
                          '공지사항이 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredNotices.length,
                        itemBuilder: (context, index) {
                          final notice = _filteredNotices[index];
                          return _buildNoticeCard(notice);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, NoticeType type, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedType = type;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildNoticeCard(Notice notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildPriorityIcon(notice.priority),
        title: Row(
          children: [
            if (notice.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '고정',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (notice.isPinned) const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notice.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('yyyy-MM-dd HH:mm').format(notice.publishDate)} · 조회 ${notice.viewCount}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showNoticeDetail(notice),
      ),
    );
  }

  Widget _buildPriorityIcon(NoticePriority priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case NoticePriority.urgent:
        icon = Icons.error;
        color = Colors.red;
        break;
      case NoticePriority.important:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case NoticePriority.normal:
        icon = Icons.info;
        color = Colors.blue;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  void _showNoticeDetail(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '작성자: ${notice.authorName} · ${DateFormat('yyyy-MM-dd HH:mm').format(notice.publishDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Text(notice.content),
              const SizedBox(height: 16),
              Text(
                '조회수: ${notice.viewCount}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
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

  void _showCreateNotice() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    NoticeType selectedType = NoticeType.center;
    NoticePriority selectedPriority = NoticePriority.normal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('공지사항 작성'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('공지 유형'),
                const SizedBox(height: 8),
                DropdownButtonFormField<NoticeType>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(
                        value: NoticeType.center, child: Text('센터 공지')),
                    DropdownMenuItem(
                        value: NoticeType.customer, child: Text('고객 공지')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('우선순위'),
                const SizedBox(height: 8),
                DropdownButtonFormField<NoticePriority>(
                  value: selectedPriority,
                  items: const [
                    DropdownMenuItem(
                        value: NoticePriority.normal, child: Text('일반')),
                    DropdownMenuItem(
                        value: NoticePriority.important, child: Text('중요')),
                    DropdownMenuItem(
                        value: NoticePriority.urgent, child: Text('긴급')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 공지사항이 등록되었습니다!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                _loadNotices();
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }
}
