import '../constants/enums.dart';

/// 공지사항 모델
class Notice {
  final String id;
  final String organizationId;
  final String title;
  final String content;
  final NoticeType type; // 센터 공지, 고객 공지
  final NoticePriority priority; // 일반, 중요, 긴급
  final List<String> targetUserIds; // 대상 사용자 ID 목록 (비어있으면 전체)
  final List<String> attachmentUrls; // 첨부 파일 URL
  final DateTime publishDate; // 게시 일시
  final DateTime? expiryDate; // 만료 일시 (null이면 무기한)
  final bool isPinned; // 상단 고정 여부
  final int viewCount; // 조회수
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Notice({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.content,
    required this.type,
    this.priority = NoticePriority.normal,
    this.targetUserIds = const [],
    this.attachmentUrls = const [],
    required this.publishDate,
    this.expiryDate,
    this.isPinned = false,
    this.viewCount = 0,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 데이터로부터 객체 생성
  factory Notice.fromFirestore(Map<String, dynamic> data, String id) {
    return Notice(
      id: id,
      organizationId: data['organization_id'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      type: _parseNoticeType(data['type'] as String?),
      priority: _parsePriority(data['priority'] as String?),
      targetUserIds:
          (data['target_user_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      attachmentUrls:
          (data['attachment_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      publishDate: (data['publish_date'] as dynamic).toDate(),
      expiryDate: data['expiry_date'] != null
          ? (data['expiry_date'] as dynamic).toDate()
          : null,
      isPinned: data['is_pinned'] as bool? ?? false,
      viewCount: data['view_count'] as int? ?? 0,
      authorId: data['author_id'] as String,
      authorName: data['author_name'] as String,
      createdAt: (data['created_at'] as dynamic).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as dynamic).toDate()
          : null,
    );
  }

  /// Firestore 저장용 데이터로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'organization_id': organizationId,
      'title': title,
      'content': content,
      'type': _noticeTypeToString(type),
      'priority': _priorityToString(priority),
      'target_user_ids': targetUserIds,
      'attachment_urls': attachmentUrls,
      'publish_date': publishDate,
      'expiry_date': expiryDate,
      'is_pinned': isPinned,
      'view_count': viewCount,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static NoticeType _parseNoticeType(String? type) {
    switch (type?.toUpperCase()) {
      case 'CENTER':
        return NoticeType.center;
      case 'CUSTOMER':
        return NoticeType.customer;
      default:
        return NoticeType.center;
    }
  }

  static String _noticeTypeToString(NoticeType type) {
    switch (type) {
      case NoticeType.center:
        return 'CENTER';
      case NoticeType.customer:
        return 'CUSTOMER';
    }
  }

  static NoticePriority _parsePriority(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'NORMAL':
        return NoticePriority.normal;
      case 'IMPORTANT':
        return NoticePriority.important;
      case 'URGENT':
        return NoticePriority.urgent;
      default:
        return NoticePriority.normal;
    }
  }

  static String _priorityToString(NoticePriority priority) {
    switch (priority) {
      case NoticePriority.normal:
        return 'NORMAL';
      case NoticePriority.important:
        return 'IMPORTANT';
      case NoticePriority.urgent:
        return 'URGENT';
    }
  }

  /// 타입별 한글 텍스트
  String get typeText {
    switch (type) {
      case NoticeType.center:
        return '센터 공지';
      case NoticeType.customer:
        return '고객 공지';
    }
  }

  /// 우선순위별 한글 텍스트
  String get priorityText {
    switch (priority) {
      case NoticePriority.normal:
        return '일반';
      case NoticePriority.important:
        return '중요';
      case NoticePriority.urgent:
        return '긴급';
    }
  }

  /// 공지사항이 유효한지 확인
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(publishDate) &&
        (expiryDate == null || now.isBefore(expiryDate!));
  }

  /// 복사본 생성
  Notice copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? content,
    NoticeType? type,
    NoticePriority? priority,
    List<String>? targetUserIds,
    List<String>? attachmentUrls,
    DateTime? publishDate,
    DateTime? expiryDate,
    bool? isPinned,
    int? viewCount,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notice(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      publishDate: publishDate ?? this.publishDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isPinned: isPinned ?? this.isPinned,
      viewCount: viewCount ?? this.viewCount,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
