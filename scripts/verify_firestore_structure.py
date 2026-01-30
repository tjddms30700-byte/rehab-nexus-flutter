#!/usr/bin/env python3
"""
Firestore 구조 검증 - 리부트 요구사항 준수 여부 확인
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def verify_firestore_structure():
    """Firestore 구조가 리부트 요구사항을 준수하는지 확인"""
    
    try:
        # Firebase 초기화
        if not firebase_admin._apps:
            cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        print("=" * 80)
        print("🔍 Firestore 구조 검증 - 리부트 요구사항")
        print("=" * 80)
        
        issues = []
        
        # 1. Users roles Map 검증
        print("\n📋 1. Users roles Map 검증:")
        users_ref = db.collection('users')
        users = users_ref.get()
        
        hayujeong_found = False
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            email = user_data.get('email', '')
            
            if email == 'dbwjd3206@naver.com':
                hayujeong_found = True
                roles = user_data.get('roles', {})
                
                print(f"\n✅ 하유정 계정 발견: {user_doc.id}")
                print(f"   Email: {email}")
                print(f"   Name: {user_data.get('name', 'N/A')}")
                print(f"   Roles: {roles}")
                
                # roles 검증
                if not isinstance(roles, dict):
                    issues.append("❌ roles가 Map이 아님!")
                else:
                    required_roles = ['owner', 'admin', 'therapist']
                    missing_roles = [r for r in required_roles if not roles.get(r, False)]
                    
                    if missing_roles:
                        issues.append(f"❌ 하유정 계정에 누락된 roles: {missing_roles}")
                    else:
                        print(f"   ✅ owner/admin/therapist 모두 true")
        
        if not hayujeong_found:
            issues.append("❌ 하유정 계정(dbwjd3206@naver.com)을 찾을 수 없음")
        
        # 2. Patients 필수 필드 검증
        print("\n📋 2. Patients 필수 필드 검증:")
        patients_ref = db.collection('patients')
        patients = patients_ref.get()
        
        patient_count = 0
        for patient_doc in patients:
            patient_data = patient_doc.to_dict()
            patient_count += 1
            
            name = patient_data.get('name', 'N/A')
            org_id = patient_data.get('organization_id')
            guardian_uids = patient_data.get('guardianUids', patient_data.get('guardian_uids', []))
            primary_therapist = patient_data.get('primaryTherapistUid', patient_data.get('primary_therapist_uid'))
            
            print(f"\n   환자: {name}")
            print(f"   - organization_id: {'✅' if org_id else '❌ 누락'}")
            print(f"   - guardianUids: {len(guardian_uids)}명")
            print(f"   - primaryTherapistUid: {'✅' if primary_therapist else '❌ 누락'}")
            
            if not org_id:
                issues.append(f"❌ {name}: organization_id 누락")
        
        print(f"\n   총 환자 수: {patient_count}명")
        
        # 3. Appointments 구조 검증
        print("\n📋 3. Appointments 컬렉션 검증:")
        appointments_ref = db.collection('appointments')
        appointments = appointments_ref.get()
        
        appointment_count = len(appointments.docs) if appointments else 0
        print(f"   총 일정 수: {appointment_count}건")
        
        if appointment_count > 0:
            sample = appointments.docs[0].to_dict()
            print(f"   샘플 필드: {list(sample.keys())[:10]}")
        else:
            print("   ⚠️  appointments 데이터 없음")
        
        # 4. Sessions 구조 검증
        print("\n📋 4. Sessions 컬렉션 검증:")
        sessions_ref = db.collection('sessions')
        sessions = sessions_ref.get()
        
        session_count = len(sessions.docs) if sessions else 0
        print(f"   총 세션 수: {session_count}건")
        
        if session_count > 0:
            sample = sessions.docs[0].to_dict()
            print(f"   샘플 필드: {list(sample.keys())}")
        else:
            print("   ⚠️  sessions 데이터 없음")
        
        # 5. Vouchers 구조 검증
        print("\n📋 5. Vouchers 컬렉션 검증:")
        vouchers_ref = db.collection('vouchers')
        vouchers = vouchers_ref.get()
        
        voucher_count = len(vouchers.docs) if vouchers else 0
        print(f"   총 이용권 수: {voucher_count}건")
        
        # 6. Recurring Rules 검증
        print("\n📋 6. Recurring Rules 컬렉션 검증:")
        recurring_ref = db.collection('recurring_rules')
        recurring = recurring_ref.get()
        
        recurring_count = len(recurring.docs) if recurring else 0
        print(f"   총 고정수업 규칙: {recurring_count}건")
        
        if recurring_count == 0:
            issues.append("⚠️  recurring_rules 컬렉션이 비어있거나 존재하지 않음")
        
        # 최종 판정
        print("\n" + "=" * 80)
        if not issues:
            print("✅ 모든 검증 통과!")
            print("✅ Firestore 구조가 리부트 요구사항을 준수합니다.")
        else:
            print("❌ 다음 이슈를 수정해야 합니다:")
            for issue in issues:
                print(f"   {issue}")
        
        print("=" * 80)
        
        return len(issues) == 0
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = verify_firestore_structure()
    sys.exit(0 if success else 1)
