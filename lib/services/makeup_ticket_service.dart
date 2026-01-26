import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/makeup_ticket.dart';
import '../constants/enums.dart';

/// 보강 티켓 관리 서비스
class MakeupTicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 보강 티켓 생성
  Future<String> createMakeupTicket(MakeupTicket ticket) async {
    try {
      final docRef = await _firestore
          .collection('makeup_tickets')
          .add(ticket.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 보강 티켓 조회
  Future<MakeupTicket?> getMakeupTicket(String ticketId) async {
    try {
      final doc =
          await _firestore.collection('makeup_tickets').doc(ticketId).get();
      if (!doc.exists) return null;
      return MakeupTicket.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 환자별 사용 가능한 보강권 조회
  Future<List<MakeupTicket>> getAvailableTickets(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('makeup_tickets')
          .where('patient_id', isEqualTo: patientId)
          .get();

      final tickets = querySnapshot.docs
          .map((doc) => MakeupTicket.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 사용 가능한 티켓만 필터링 및 정렬
      final availableTickets = tickets.where((ticket) {
        return ticket.status == MakeupTicketStatus.available &&
            DateTime.now().isBefore(ticket.expiryDate);
      }).toList();

      availableTickets.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      return availableTickets;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 환자별 모든 보강권 조회
  Future<List<MakeupTicket>> getAllTicketsByPatient(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('makeup_tickets')
          .where('patient_id', isEqualTo: patientId)
          .get();

      final tickets = querySnapshot.docs
          .map((doc) => MakeupTicket.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 정렬 (최신순)
      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tickets;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 보강권 사용
  Future<void> useMakeupTicket(String ticketId, String attendanceId) async {
    try {
      await _firestore.collection('makeup_tickets').doc(ticketId).update({
        'status': 'USED',
        'used_date': DateTime.now(),
        'used_attendance_id': attendanceId,
        'updated_at': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 만료된 보강권 자동 처리
  Future<void> expireOldTickets(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('makeup_tickets')
          .where('patient_id', isEqualTo: patientId)
          .where('status', isEqualTo: 'AVAILABLE')
          .get();

      final now = DateTime.now();
      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        final ticket = MakeupTicket.fromFirestore(doc.data(), doc.id);
        if (now.isAfter(ticket.expiryDate)) {
          batch.update(doc.reference, {
            'status': 'EXPIRED',
            'updated_at': now,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 보강권 통계
  Future<Map<String, int>> getTicketStatistics(String patientId) async {
    try {
      final tickets = await getAllTicketsByPatient(patientId);

      int available = 0;
      int used = 0;
      int expired = 0;

      for (var ticket in tickets) {
        switch (ticket.status) {
          case MakeupTicketStatus.available:
            if (DateTime.now().isBefore(ticket.expiryDate)) {
              available++;
            } else {
              expired++;
            }
            break;
          case MakeupTicketStatus.used:
            used++;
            break;
          case MakeupTicketStatus.expired:
            expired++;
            break;
        }
      }

      return {
        'available': available,
        'used': used,
        'expired': expired,
        'total': available + used + expired,
      };
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }
}
