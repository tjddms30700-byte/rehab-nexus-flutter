import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/invite.dart';

/// 초대 서비스
class InviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 초대 코드 생성 (6~8자리 랜덤)
  String _generateInviteCode({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 초대 코드 해시 생성 (SHA256)
  String _hashInviteCode(String code, String salt) {
    final bytes = utf8.encode(code + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 초대 생성 (센터장 전용)
  /// 
  /// [email]: 초대할 사용자 이메일
  /// [role]: 역할 ('therapist' | 'guardian')
  /// [centerId]: 센터 ID
  /// [centerName]: 센터 이름
  /// [createdByUid]: 생성자 UID
  /// [createdByName]: 생성자 이름
  /// [patientId]: 보호자 초대 시 연결할 환자 ID (선택)
  /// [patientName]: 환자 이름 (선택)
  /// [expirationDays]: 만료 일수 (기본 7일)
  Future<Map<String, dynamic>> createInvite({
    required String email,
    required String role,
    required String centerId,
    required String centerName,
    required String createdByUid,
    required String createdByName,
    String? patientId,
    String? patientName,
    int expirationDays = 7,
  }) async {
    try {
      // 1. 초대 코드 생성
      final code = _generateInviteCode(length: 8);
      
      // 2. 코드 해시 생성 (salt = centerId)
      final codeHash = _hashInviteCode(code, centerId);
      
      // 3. 만료 시각 계산
      final expiresAt = DateTime.now().add(Duration(days: expirationDays));
      
      // 4. Firestore에 초대 생성
      final inviteRef = _firestore.collection('invites').doc();
      
      final invite = Invite(
        id: inviteRef.id,
        codeHash: codeHash,
        email: email,
        role: role,
        centerId: centerId,
        centerName: centerName,
        patientId: patientId,
        patientName: patientName,
        expiresAt: expiresAt,
        status: InviteStatus.invited,
        createdAt: DateTime.now(),
        createdByUid: createdByUid,
        createdByName: createdByName,
      );
      
      await inviteRef.set(invite.toFirestore());
      
      // 5. 초대 링크 생성
      final inviteLink = 'https://rehab-nexus.app/invite?code=$code';
      
      return {
        'success': true,
        'inviteId': invite.id,
        'code': code,
        'inviteLink': inviteLink,
        'expiresAt': expiresAt.toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': '초대 생성 실패: $e',
      };
    }
  }

  /// 초대 코드 검증
  /// 
  /// [code]: 사용자가 입력한 초대 코드
  /// [centerId]: 센터 ID (선택, 없으면 모든 센터 검색)
  Future<Map<String, dynamic>> verifyInviteCode({
    required String code,
    String? centerId,
  }) async {
    try {
      // 1. 코드 정규화 (대문자 변환)
      final normalizedCode = code.toUpperCase().trim();
      
      // 2. 모든 센터의 초대 검색 (centerId 없을 경우)
      Query query = _firestore
          .collection('invites')
          .where('status', isEqualTo: 'invited')
          .limit(50);
      
      final snapshot = await query.get();
      
      // 3. 각 초대에 대해 해시 비교
      for (var doc in snapshot.docs) {
        final invite = Invite.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        
        // 해시 계산
        final codeHash = _hashInviteCode(normalizedCode, invite.centerId);
        
        // 해시 일치 확인
        if (codeHash == invite.codeHash) {
          // 만료 확인
          if (invite.isExpired) {
            return {
              'success': false,
              'error': '만료된 초대 코드입니다',
              'errorCode': 'EXPIRED',
            };
          }
          
          // 사용 가능 확인
          if (!invite.isUsable) {
            return {
              'success': false,
              'error': '이미 사용되었거나 취소된 초대 코드입니다',
              'errorCode': 'USED_OR_CANCELLED',
            };
          }
          
          return {
            'success': true,
            'invite': invite,
            'inviteId': invite.id,
          };
        }
      }
      
      return {
        'success': false,
        'error': '유효하지 않은 초대 코드입니다',
        'errorCode': 'INVALID_CODE',
      };
    } catch (e) {
      return {
        'success': false,
        'error': '초대 코드 검증 실패: $e',
        'errorCode': 'VERIFICATION_ERROR',
      };
    }
  }

  /// 초대 수락 (회원가입 완료 시)
  /// 
  /// [inviteId]: 초대 ID
  /// [userId]: 신규 생성된 사용자 UID
  Future<bool> acceptInvite({
    required String inviteId,
    required String userId,
  }) async {
    try {
      final inviteRef = _firestore.collection('invites').doc(inviteId);
      
      // 트랜잭션으로 상태 업데이트
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(inviteRef);
        
        if (!snapshot.exists) {
          throw Exception('초대를 찾을 수 없습니다');
        }
        
        final invite = Invite.fromFirestore(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
        
        // 사용 가능 확인
        if (!invite.isUsable) {
          throw Exception('사용할 수 없는 초대입니다');
        }
        
        // 초대 상태 업데이트
        transaction.update(inviteRef, {
          'status': 'accepted',
          'used_at': FieldValue.serverTimestamp(),
          'used_by_uid': userId,
        });
        
        // 보호자인 경우 환자의 guardian 목록에 추가
        if (invite.role == 'guardian' && invite.patientId != null) {
          final patientRef = _firestore.collection('patients').doc(invite.patientId);
          transaction.update(patientRef, {
            'guardians': FieldValue.arrayUnion([userId]),
          });
        }
      });
      
      return true;
    } catch (e) {
      print('❌ 초대 수락 실패: $e');
      return false;
    }
  }

  /// 초대 취소
  /// 
  /// [inviteId]: 초대 ID
  Future<bool> cancelInvite(String inviteId) async {
    try {
      await _firestore.collection('invites').doc(inviteId).update({
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ 초대 취소 실패: $e');
      return false;
    }
  }

  /// 초대 재발송 (새 코드 생성)
  /// 
  /// [inviteId]: 기존 초대 ID
  Future<Map<String, dynamic>> resendInvite(String inviteId) async {
    try {
      // 기존 초대 조회
      final snapshot = await _firestore.collection('invites').doc(inviteId).get();
      
      if (!snapshot.exists) {
        return {
          'success': false,
          'error': '초대를 찾을 수 없습니다',
        };
      }
      
      final oldInvite = Invite.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        snapshot.id,
      );
      
      // 기존 초대 취소
      await cancelInvite(inviteId);
      
      // 새 초대 생성
      final result = await createInvite(
        email: oldInvite.email,
        role: oldInvite.role,
        centerId: oldInvite.centerId,
        centerName: oldInvite.centerName ?? '',
        createdByUid: oldInvite.createdByUid,
        createdByName: oldInvite.createdByName ?? '',
        patientId: oldInvite.patientId,
        patientName: oldInvite.patientName,
      );
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': '초대 재발송 실패: $e',
      };
    }
  }

  /// 센터별 초대 목록 조회
  /// 
  /// [centerId]: 센터 ID
  /// [status]: 상태 필터 (선택)
  Future<List<Invite>> getInvitesByCenter({
    required String centerId,
    InviteStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('invites')
          .where('center_id', isEqualTo: centerId)
          .orderBy('created_at', descending: true);
      
      if (status != null) {
        final statusString = status.toString().split('.').last;
        query = query.where('status', isEqualTo: statusString);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => Invite.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('❌ 초대 목록 조회 실패: $e');
      return [];
    }
  }

  /// 초대 상세 조회
  Future<Invite?> getInviteById(String inviteId) async {
    try {
      final snapshot = await _firestore.collection('invites').doc(inviteId).get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      return Invite.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        snapshot.id,
      );
    } catch (e) {
      print('❌ 초대 조회 실패: $e');
      return null;
    }
  }

  /// 초대 통계 (센터별)
  Future<Map<String, int>> getInviteStatsByCenter(String centerId) async {
    try {
      final snapshot = await _firestore
          .collection('invites')
          .where('center_id', isEqualTo: centerId)
          .get();
      
      int total = snapshot.docs.length;
      int invited = 0;
      int accepted = 0;
      int expired = 0;
      int cancelled = 0;
      
      for (var doc in snapshot.docs) {
        final invite = Invite.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        switch (invite.status) {
          case InviteStatus.invited:
            invited++;
            if (invite.isExpired) {
              expired++;
            }
            break;
          case InviteStatus.accepted:
            accepted++;
            break;
          case InviteStatus.expired:
            expired++;
            break;
          case InviteStatus.cancelled:
            cancelled++;
            break;
        }
      }
      
      return {
        'total': total,
        'invited': invited,
        'accepted': accepted,
        'expired': expired,
        'cancelled': cancelled,
      };
    } catch (e) {
      print('❌ 초대 통계 조회 실패: $e');
      return {
        'total': 0,
        'invited': 0,
        'accepted': 0,
        'expired': 0,
        'cancelled': 0,
      };
    }
  }
}
