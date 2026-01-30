#!/usr/bin/env python3
"""
Firestore organization_id 필드 검증 스크립트
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def verify_organization_id():
    """모든 users와 patients에 organization_id가 있는지 확인"""
    
    try:
        # Firebase 초기화
        if not firebase_admin._apps:
            cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        print("=" * 70)
        print("🔍 Firestore organization_id 필드 검증")
        print("=" * 70)
        
        # 1. Users 검증
        print("\n📋 Users 컬렉션 검증:")
        users_ref = db.collection('users')
        users = users_ref.get()
        
        users_missing = []
        users_with_org = []
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            user_id = user_doc.id
            email = user_data.get('email', 'N/A')
            name = user_data.get('name', 'N/A')
            org_id = user_data.get('organization_id')
            
            if org_id:
                users_with_org.append({
                    'id': user_id,
                    'email': email,
                    'name': name,
                    'organization_id': org_id
                })
            else:
                users_missing.append({
                    'id': user_id,
                    'email': email,
                    'name': name
                })
        
        print(f"✅ organization_id 있음: {len(users_with_org)}명")
        for user in users_with_org:
            print(f"   - {user['name']} ({user['email']}): {user['organization_id']}")
        
        if users_missing:
            print(f"\n❌ organization_id 없음: {len(users_missing)}명")
            for user in users_missing:
                print(f"   - {user['name']} ({user['email']})")
        
        # 2. Patients 검증
        print("\n📋 Patients 컬렉션 검증:")
        patients_ref = db.collection('patients')
        patients = patients_ref.get()
        
        patients_missing = []
        patients_with_org = []
        
        for patient_doc in patients:
            patient_data = patient_doc.to_dict()
            patient_id = patient_doc.id
            name = patient_data.get('name', 'N/A')
            org_id = patient_data.get('organization_id')
            
            if org_id:
                patients_with_org.append({
                    'id': patient_id,
                    'name': name,
                    'organization_id': org_id
                })
            else:
                patients_missing.append({
                    'id': patient_id,
                    'name': name
                })
        
        print(f"✅ organization_id 있음: {len(patients_with_org)}명")
        for patient in patients_with_org:
            print(f"   - {patient['name']}: {patient['organization_id']}")
        
        if patients_missing:
            print(f"\n❌ organization_id 없음: {len(patients_missing)}명")
            for patient in patients_missing:
                print(f"   - {patient['name']}")
        
        # 3. 최종 판정
        print("\n" + "=" * 70)
        if not users_missing and not patients_missing:
            print("✅ 모든 데이터에 organization_id 필드가 존재합니다!")
            print("✅ Flutter 앱이 정상 작동할 것으로 예상됩니다.")
        else:
            print("❌ 일부 데이터에 organization_id가 누락되었습니다.")
            print("⚠️  누락된 데이터는 앱에서 표시되지 않을 수 있습니다.")
            
            if users_missing or patients_missing:
                print("\n🔧 수정 방법:")
                print("   migrate_firestore_structure.py 스크립트를 실행하여 데이터를 재생성하세요.")
        
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    verify_organization_id()
