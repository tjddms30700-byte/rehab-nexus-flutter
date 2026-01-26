import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import '../constants/enums.dart';

/// 출석 관리 서비스
class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 출석 생성
  Future<String> createAttendance(Attendance attendance) async {
    try {
      final docRef =
          await _firestore.collection('attendances').add(attendance.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 출석 조회
  Future<Attendance?> getAttendance(String attendanceId) async {
    try {
      final doc =
          await _firestore.collection('attendances').doc(attendanceId).get();
      if (!doc.exists) return null;
      return Attendance.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 환자별 출석 목록 조회
  Future<List<Attendance>> getAttendancesByPatient(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendances')
          .where('patient_id', isEqualTo: patientId)
          .get();

      final attendances = querySnapshot.docs
          .map((doc) => Attendance.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 정렬
      attendances.sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));

      return attendances;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 치료사별 출석 목록 조회
  Future<List<Attendance>> getAttendancesByTherapist(
      String therapistId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendances')
          .where('therapist_id', isEqualTo: therapistId)
          .get();

      final attendances = querySnapshot.docs
          .map((doc) => Attendance.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 날짜 필터링 및 정렬
      final filtered = attendances.where((attendance) {
        return attendance.scheduleDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            attendance.scheduleDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      filtered.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));

      return filtered;
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 출석 상태 업데이트
  Future<void> updateAttendanceStatus(
      String attendanceId, AttendanceStatus status,
      {String? cancelReason}) async {
    try {
      final updateData = {
        'status': _statusToString(status),
        'updated_at': DateTime.now(),
      };

      if (cancelReason != null) {
        updateData['cancel_reason'] = cancelReason;
      }

      await _firestore
          .collection('attendances')
          .doc(attendanceId)
          .update(updateData);
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  /// 출석 통계 조회 (월별)
  Future<Map<String, int>> getMonthlyStatistics(
      String patientId, int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final querySnapshot = await _firestore
          .collection('attendances')
          .where('patient_id', isEqualTo: patientId)
          .get();

      final attendances = querySnapshot.docs
          .map((doc) => Attendance.fromFirestore(doc.data(), doc.id))
          .toList();

      // 메모리에서 월별 필터링
      final monthlyAttendances = attendances.where((attendance) {
        return attendance.scheduleDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            attendance.scheduleDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // 통계 계산
      int present = 0;
      int absent = 0;
      int cancelled = 0;
      int makeup = 0;

      for (var attendance in monthlyAttendances) {
        switch (attendance.status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.cancelled:
            cancelled++;
            break;
          case AttendanceStatus.makeup:
            makeup++;
            break;
        }
      }

      return {
        'present': present,
        'absent': absent,
        'cancelled': cancelled,
        'makeup': makeup,
        'total': present + absent + cancelled + makeup,
      };
    } catch (e) {
      throw Exception('Firebase 연결 오류: $e');
    }
  }

  static String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.cancelled:
        return 'CANCELLED';
      case AttendanceStatus.makeup:
        return 'MAKEUP';
    }
  }
}
