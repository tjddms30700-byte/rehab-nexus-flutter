import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';
import '../constants/enums.dart';

/// 목표 데이터 서비스
class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'goals';

  /// 목표 생성
  Future<String> createGoal(Goal goal) async {
    try {
      final docRef = await _firestore.collection(_collection).add(goal.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('목표 저장 실패: $e');
    }
  }

  /// 목표 조회 (ID)
  Future<Goal?> getGoal(String goalId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(goalId).get();
      if (!doc.exists) return null;
      return Goal.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('목표 조회 실패: $e');
    }
  }

  /// 환자별 목표 목록 조회
  Future<List<Goal>> getGoalsByPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Goal.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('목표 목록 조회 실패: $e');
    }
  }

  /// 활성 목표 조회
  Future<List<Goal>> getActiveGoals(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .where('status', isEqualTo: 'IN_PROGRESS')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Goal.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('활성 목표 조회 실패: $e');
    }
  }

  /// 목표 상태별 조회
  Future<List<Goal>> getGoalsByStatus(String patientId, String status) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .where('status', isEqualTo: status)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Goal.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('목표 상태별 조회 실패: $e');
    }
  }

  /// 목표 업데이트
  Future<void> updateGoal(String goalId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(goalId).update(updates);
    } catch (e) {
      throw Exception('목표 업데이트 실패: $e');
    }
  }

  /// 목표 진행률 업데이트
  Future<void> updateGoalProgress(String goalId, double progressPercentage) async {
    try {
      final updates = {
        'progress_percentage': progressPercentage,
        'updated_at': Timestamp.now(),
      };

      // 100% 달성 시 상태를 ACHIEVED로 변경
      if (progressPercentage >= 100.0) {
        updates['status'] = 'ACHIEVED';
      }

      await _firestore.collection(_collection).doc(goalId).update(updates);
    } catch (e) {
      throw Exception('목표 진행률 업데이트 실패: $e');
    }
  }

  /// 목표 상태 변경
  Future<void> updateGoalStatus(String goalId, String status) async {
    try {
      await _firestore.collection(_collection).doc(goalId).update({
        'status': status,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('목표 상태 변경 실패: $e');
    }
  }

  /// 목표 삭제
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore.collection(_collection).doc(goalId).delete();
    } catch (e) {
      throw Exception('목표 삭제 실패: $e');
    }
  }

  /// 우선순위별 목표 조회
  Future<List<Goal>> getGoalsByPriority(String patientId, String priority) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patient_id', isEqualTo: patientId)
          .where('priority', isEqualTo: priority)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Goal.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('우선순위별 목표 조회 실패: $e');
    }
  }

  /// Stream으로 목표 실시간 감시
  Stream<List<Goal>> watchGoalsByPatient(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Goal.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  /// 달성률 통계
  Future<Map<String, dynamic>> getGoalStatistics(String patientId) async {
    try {
      final goals = await getGoalsByPatient(patientId);
      
      final total = goals.length;
      final achieved = goals.where((g) => g.status == GoalStatus.achieved).length;
      final inProgress = goals.where((g) => g.status == GoalStatus.inProgress).length;
      final revised = goals.where((g) => g.status == GoalStatus.revised).length;
      final cancelled = goals.where((g) => g.status == GoalStatus.cancelled).length;
      
      final averageProgress = total > 0
          ? goals.map((g) => g.progressPercentage).reduce((a, b) => a + b) / total
          : 0.0;

      return {
        'total': total,
        'achieved': achieved,
        'in_progress': inProgress,
        'revised': revised,
        'cancelled': cancelled,
        'achievement_rate': total > 0 ? (achieved / total * 100) : 0.0,
        'average_progress': averageProgress,
      };
    } catch (e) {
      throw Exception('목표 통계 조회 실패: $e');
    }
  }
}
