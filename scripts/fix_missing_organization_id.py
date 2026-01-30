#!/usr/bin/env python3
"""
누락된 patients에 organization_id 추가
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def fix_missing_organization_id():
    """patients에 organization_id 추가"""
    
    try:
        # Firebase 초기화
        if not firebase_admin._apps:
            cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        print("=" * 70)
        print("🔧 Patients organization_id 자동 수정")
        print("=" * 70)
        
        # 누락된 환자 찾기
        patients_ref = db.collection('patients')
        patients = patients_ref.get()
        
        updated_count = 0
        
        for patient_doc in patients:
            patient_data = patient_doc.to_dict()
            patient_id = patient_doc.id
            name = patient_data.get('name', 'N/A')
            org_id = patient_data.get('organization_id')
            
            if not org_id:
                # organization_id가 없는 경우
                # CENTER_AQULAB_WIRYE를 기본값으로 설정
                default_org_id = "CENTER_AQULAB_WIRYE"
                
                print(f"\n🔧 수정 중: {name} (ID: {patient_id})")
                print(f"   organization_id 추가: {default_org_id}")
                
                # 업데이트
                db.collection('patients').document(patient_id).update({
                    'organization_id': default_org_id
                })
                
                updated_count += 1
                print(f"   ✅ 업데이트 완료")
        
        print("\n" + "=" * 70)
        print(f"✅ 총 {updated_count}명의 환자 데이터 업데이트 완료")
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    fix_missing_organization_id()
