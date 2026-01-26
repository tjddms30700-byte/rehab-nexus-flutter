import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';
import '../constants/enums.dart';

/// 공지사항 관리 서비스
class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 공지사항 생성
  Future<String> createNotice(Notice notice) async {
    try {
      final docRef =
          await _firestore.collection('notices').add(notice.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 공지사항 조회
  Future<Notice?> getNotice(String noticeId) async {
    try {
      final doc = await _firestore.collection('notices').doc(noticeId).get();
      if (!doc.exists) return null;
      return Notice.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 센터별 공지사항 목록 조회
  Future<List<Notice>> getNoticesByOrganization(
      String organizationId, NoticeType type) async {
    try {
      final querySnapshot = await _firestore
          .collection('notices')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      final notices = querySnapshot.docs
          .map((doc) => Notice.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 타입 필터링 및 정렬
      final filteredNotices = notices.where((notice) {
        return notice.type == type && notice.isActive;
      }).toList();

      filteredNotices.sort((a, b) {
        // 상단 고정 우선
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        // 우선순위 순서
        final priorityOrder = {
          NoticePriority.urgent: 0,
          NoticePriority.important: 1,
          NoticePriority.normal: 2,
        };
        final aPriority = priorityOrder[a.priority] ?? 2;
        final bPriority = priorityOrder[b.priority] ?? 2;
        
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
        
        // 최신순
        return b.publishDate.compareTo(a.publishDate);
      });

      return filteredNotices;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 사용자별 공지사항 조회 (대상 지정된 공지만)
  Future<List<Notice>> getNoticesByUser(
      String organizationId, String userId, NoticeType type) async {
    try {
      final querySnapshot = await _firestore
          .collection('notices')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      final notices = querySnapshot.docs
          .map((doc) => Notice.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 필터링 및 정렬
      final filteredNotices = notices.where((notice) {
        return notice.type == type &&
            notice.isActive &&
            (notice.targetUserIds.isEmpty ||
                notice.targetUserIds.contains(userId));
      }).toList();

      filteredNotices.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        final priorityOrder = {
          NoticePriority.urgent: 0,
          NoticePriority.important: 1,
          NoticePriority.normal: 2,
        };
        final aPriority = priorityOrder[a.priority] ?? 2;
        final bPriority = priorityOrder[b.priority] ?? 2;
        
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
        
        return b.publishDate.compareTo(a.publishDate);
      });

      return filteredNotices;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 공지사항 수정
  Future<void> updateNotice(String noticeId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now();
      await _firestore.collection('notices').doc(noticeId).update(data);
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 공지사항 삭제
  Future<void> deleteNotice(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).delete();
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 조회수 증가
  Future<void> incrementViewCount(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).update({
        'view_count': FieldValue.increment(1),
        'updated_at': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 상단 고정 토글
  Future<void> togglePin(String noticeId, bool isPinned) async {
    try {
      await _firestore.collection('notices').doc(noticeId).update({
        'is_pinned': isPinned,
        'updated_at': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 만료된 공지사항 자동 삭제 (선택적)
  Future<void> cleanExpiredNotices(String organizationId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notices')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      final now = DateTime.now();
      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        final notice = Notice.fromFirestore(doc.data(), doc.id);
        if (notice.expiryDate != null && now.isAfter(notice.expiryDate!)) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }
}
