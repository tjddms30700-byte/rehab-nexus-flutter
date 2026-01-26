import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore 데이터베이스 서비스
/// 
/// 실제 Firebase Firestore와 연동하여 데이터를 저장/조회합니다.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 환자 (Patients) 관련
  // ========================================

  /// 환자 생성
  Future<String> createPatient(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('patients').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 환자 생성 성공 (ID: ${docRef.id})');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 환자 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 환자 조회 (단일)
  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    try {
      final doc = await _firestore.collection('patients').doc(patientId).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ Firestore: 환자를 찾을 수 없음 (ID: $patientId)');
        }
        return null;
      }
      
      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 환자 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 환자 목록 조회 (조직별)
  Future<List<Map<String, dynamic>>> getPatientsByOrganization(
    String organizationId,
  ) async {
    try {
      // ✅ 인덱스 없이 작동하도록 orderBy 제거
      final querySnapshot = await _firestore
          .collection('patients')
          .where('organization_id', isEqualTo: organizationId)
          .get();
      
      final patients = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      
      // ✅ 메모리에서 정렬 (인덱스 불필요)
      patients.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // 최신순
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 환자 목록 조회 성공 (${patients.length}명)');
      }
      
      return patients;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 환자 목록 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 환자 업데이트
  Future<void> updatePatient(String patientId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('patients').doc(patientId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 환자 업데이트 성공 (ID: $patientId)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 환자 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 예약 (Appointments) 관련
  // ========================================

  /// 예약 생성
  Future<String> createAppointment(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('appointments').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 예약 생성 성공 (ID: ${docRef.id})');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 예약 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 예약 조회 (치료사별, 날짜별)
  Future<List<Map<String, dynamic>>> getAppointmentsByTherapist(
    String therapistId,
    DateTime date,
  ) async {
    try {
      // 날짜 범위 설정 (해당 날짜의 00:00 ~ 23:59)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // ✅ 단순 쿼리: therapist_id만 조회
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('therapist_id', isEqualTo: therapistId)
          .get();
      
      // ✅ 메모리에서 날짜 필터링 및 정렬
      final appointments = querySnapshot.docs
          .map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          })
          .where((doc) {
            final appointmentDate = (doc['appointment_date'] as Timestamp?)?.toDate();
            if (appointmentDate == null) return false;
            return appointmentDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   appointmentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .toList();
      
      // 날짜순 정렬
      appointments.sort((a, b) {
        final aTime = a['appointment_date'] as Timestamp?;
        final bTime = b['appointment_date'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 예약 목록 조회 성공 (${appointments.length}건)');
      }
      
      return appointments;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 예약 목록 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 예약 상태 업데이트
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 예약 상태 업데이트 성공 (ID: $appointmentId, 상태: $status)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 예약 상태 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 출석 (Attendance) 관련
  // ========================================

  /// 출석 기록 생성
  Future<String> createAttendance(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('attendances').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 출석 기록 생성 성공 (ID: ${docRef.id})');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 출석 기록 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 출석 기록 조회 (날짜별)
  Future<List<Map<String, dynamic>>> getAttendancesByDate(
    String therapistId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // ✅ 단순 쿼리: therapist_id만 조회
      final querySnapshot = await _firestore
          .collection('attendances')
          .where('therapist_id', isEqualTo: therapistId)
          .get();
      
      // ✅ 메모리에서 날짜 필터링
      final attendances = querySnapshot.docs
          .map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          })
          .where((doc) {
            final scheduleDate = (doc['schedule_date'] as Timestamp?)?.toDate();
            if (scheduleDate == null) return false;
            return scheduleDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   scheduleDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .toList();
      
      if (kDebugMode) {
        print('✅ Firestore: 출석 기록 조회 성공 (${attendances.length}건)');
      }
      
      return attendances;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 출석 기록 조회 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 문의 (Inquiries) 관련
  // ========================================

  /// 문의 생성
  Future<String> createInquiry(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('inquiries').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 문의 생성 성공 (ID: ${docRef.id})');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 문의 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 문의 목록 조회 (치료사별)
  Future<List<Map<String, dynamic>>> getInquiriesByTherapist(
    String therapistId,
  ) async {
    try {
      // ✅ 인덱스 없이 작동하도록 orderBy 제거
      final querySnapshot = await _firestore
          .collection('inquiries')
          .where('therapist_id', isEqualTo: therapistId)
          .get();
      
      final inquiries = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      
      // ✅ 메모리에서 정렬
      inquiries.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 문의 목록 조회 성공 (${inquiries.length}건)');
      }
      
      return inquiries;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 문의 목록 조회 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 보강권 (MakeupTickets) 관련
  // ========================================

  /// 보강권 발급
  Future<String> createMakeupTicket(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('makeup_tickets').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Firestore: 보강권 발급 성공 (ID: ${docRef.id})');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: 보강권 발급 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 유틸리티
  // ========================================

  /// Firestore 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      if (kDebugMode) {
        print('🔄 Firestore: 연결 테스트 시작...');
        print('📍 Project ID: rehab-nexus-korea');
        print('📍 Region: asia-northeast3 (Seoul)');
      }
      
      await _firestore.collection('_health_check').limit(1).get();
      
      if (kDebugMode) {
        print('✅ Firestore: 연결 성공!');
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Firestore: 연결 실패');
        print('오류 타입: ${e.runtimeType}');
        print('오류 메시지: $e');
        print('스택 트레이스: $stackTrace');
      }
      return false;
    }
  }

  /// 컬렉션 데이터 개수 조회
  Future<int> getCollectionCount(String collectionName) async {
    try {
      final querySnapshot = await _firestore.collection(collectionName).count().get();
      final count = querySnapshot.count ?? 0;
      
      if (kDebugMode) {
        print('✅ Firestore: $collectionName 개수 조회 성공 ($count개)');
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore: $collectionName 개수 조회 실패 - $e');
      }
      return 0;
    }
  }
}
