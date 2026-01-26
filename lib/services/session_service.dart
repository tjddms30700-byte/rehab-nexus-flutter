import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart';

/// 세션 데이터 서비스
class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'sessions';

  /// 세션 생성
  Future<String> createSession(Session session) async {
    try {
      final docRef = await _firestore.collection(_collection).add(session.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('세션 저장 실패: $e');
    }
  }

  /// 세션 조회 (ID)
  Future<Session?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(sessionId).get();
      if (!doc.exists) return null;
      return Session.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('세션 조회 실패: $e');
    }
  }

  /// 환자별 세션 목록 조회
  Future<List<Session>> getSessionsByPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .orderBy('session_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('세션 목록 조회 실패: $e');
    }
  }

  /// 기간별 세션 조회
  Future<List<Session>> getSessionsByDateRange(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .where('session_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('session_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('session_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('기간별 세션 조회 실패: $e');
    }
  }

  /// 최근 N개 세션 조회
  Future<List<Session>> getRecentSessions(String patientId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .orderBy('session_date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('최근 세션 조회 실패: $e');
    }
  }

  /// 세션 업데이트
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).update(updates);
    } catch (e) {
      throw Exception('세션 업데이트 실패: $e');
    }
  }

  /// 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).delete();
    } catch (e) {
      throw Exception('세션 삭제 실패: $e');
    }
  }

  /// 치료사별 세션 목록 조회
  Future<List<Session>> getSessionsByTherapist(String therapistId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('therapist_id', isEqualTo: therapistId)
          .where('session_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('session_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('session_date')
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('치료사 세션 목록 조회 실패: $e');
    }
  }

  /// Stream으로 세션 실시간 감시
  Stream<List<Session>> watchSessionsByPatient(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patient_id', isEqualTo: patientId)
        .orderBy('session_date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Session.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  /// 세션 통계
  Future<Map<String, dynamic>> getSessionStatistics(String patientId) async {
    try {
      final sessions = await getSessionsByPatient(patientId);
      
      final total = sessions.length;
      final thisMonth = sessions.where((s) {
        final now = DateTime.now();
        return s.sessionDate.year == now.year && s.sessionDate.month == now.month;
      }).length;
      
      // 각 세션의 활동 시간 합계 계산
      final totalDuration = sessions.fold<int>(
        0,
        (sum, s) => sum + s.activities.fold<int>(0, (actSum, act) => actSum + act.durationMinutes),
      );

      return {
        'total_sessions': total,
        'this_month': thisMonth,
        'total_duration_minutes': totalDuration,
        'average_duration': total > 0 ? (totalDuration / total).toDouble() : 0.0,
      };
    } catch (e) {
      throw Exception('세션 통계 조회 실패: $e');
    }
  }
}
