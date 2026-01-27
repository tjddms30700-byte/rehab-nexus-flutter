import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../constants/enums.dart';

/// 예약 서비스
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'appointments';

  /// 예약 생성
  Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(appointment.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('예약 생성 실패: $e');
    }
  }

  /// 예약 조회 (ID)
  Future<Appointment?> getAppointment(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(appointmentId)
          .get();

      if (!doc.exists) return null;
      return Appointment.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('예약 조회 실패: $e');
    }
  }

  /// 보호자의 예약 목록 조회 (인덱스 불필요 - 단순 쿼리)
  Future<List<Appointment>> getAppointmentsByGuardian(String guardianId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('guardian_id', isEqualTo: guardianId)
          // orderBy 제거: 앱에서 정렬 처리 (복합 인덱스 불필요)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // 앱에서 정렬 (최신순)
      appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      
      return appointments;
    } catch (e) {
      throw Exception('예약 목록 조회 실패: $e');
    }
  }

  /// 치료사의 예약 목록 조회 (인덱스 불필요 - 단순 쿼리)
  Future<List<Appointment>> getAppointmentsByTherapist(String therapistId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('therapist_id', isEqualTo: therapistId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
          .toList();

      // 앱에서 정렬 (인덱스 불필요)
      appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      return appointments;
    } catch (e) {
      print('❌ 예약 목록 조회 실패: $e');
      throw Exception('예약 목록 조회 실패: $e');
    }
  }

  /// 특정 날짜의 예약 목록 조회 (인덱스 불필요 - 단순 쿼리 + 앱 필터링)
  Future<List<Appointment>> getAppointmentsByDate(
    String therapistId,
    DateTime date,
  ) async {
    try {
      // 단순 쿼리: therapist_id만 필터링 (복합 인덱스 불필요)
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('therapist_id', isEqualTo: therapistId)
          .get();

      final allAppointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
          .toList();

      // 앱에서 날짜 필터링
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final filteredAppointments = allAppointments.where((appointment) {
        return appointment.appointmentDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
               appointment.appointmentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();

      // 시간순 정렬
      filteredAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      return filteredAppointments;
    } catch (e) {
      print('❌ 날짜별 예약 조회 실패: $e');
      throw Exception('날짜별 예약 조회 실패: $e');
    }
  }

  /// 예약 상태 변경
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? therapistNotes,
  }) async {
    try {
      final updateData = {
        'status': _statusToString(status),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (therapistNotes != null) {
        updateData['therapist_notes'] = therapistNotes;
      }

      await _firestore
          .collection(_collectionName)
          .doc(appointmentId)
          .update(updateData);
    } catch (e) {
      throw Exception('예약 상태 변경 실패: $e');
    }
  }

  /// 예약 취소
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.cancelled,
      );
    } catch (e) {
      throw Exception('예약 취소 실패: $e');
    }
  }

  /// 예약 승인
  Future<void> confirmAppointment(String appointmentId, {String? notes}) async {
    try {
      await updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.confirmed,
        therapistNotes: notes,
      );
    } catch (e) {
      throw Exception('예약 승인 실패: $e');
    }
  }

  /// 예약 완료 처리
  Future<void> completeAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.completed,
      );
    } catch (e) {
      throw Exception('예약 완료 처리 실패: $e');
    }
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.completed:
        return 'COMPLETED';
    }
  }
}
